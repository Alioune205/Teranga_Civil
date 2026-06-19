import datetime
from django.utils import timezone
from django.core.cache import cache
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from apps.etat_civil.models_attribution import AttributionDossier, JournalAttribution, ProfilAgent
from apps.etat_civil.services.moteur_scoring import MoteurScoring
from apps.etat_civil.services.moteur_priorite import MoteurPriorite

class ServiceAttribution:
    def __init__(self):
        self.moteur_scoring = MoteurScoring()
        self.moteur_priorite = MoteurPriorite()

    def attribuer(self, dossier):
        # 1. Vérifier si l'attribution automatique est suspendue pour la commune
        commune_id = getattr(dossier, 'commune_id', None)
        if commune_id and self.est_attribution_suspendue(commune_id):
            return None, "Attribution automatique suspendue pour cette commune."

        # 1b. Vérifier la pause automatique globale (13h30 - 15h00)
        from django.conf import settings
        pause_start_str = getattr(settings, 'DISPATCH_PAUSE_START', '13:30')
        pause_end_str = getattr(settings, 'DISPATCH_PAUSE_END', '15:00')
        now_time = timezone.now().astimezone().time()
        
        try:
            pause_start = datetime.datetime.strptime(pause_start_str, "%H:%M").time()
            pause_end = datetime.datetime.strptime(pause_end_str, "%H:%M").time()
            if pause_start <= now_time <= pause_end:
                return None, f"Pause automatique en cours ({pause_start_str}-{pause_end_str}). Aucune attribution."
        except ValueError:
            pass # Si le format de configuration est invalide, ignorer la pause globale


        # 2. Calculer la priorité
        priorite = self.moteur_priorite.calculer_priorite(dossier)

        # 3. Trouver le meilleur agent
        agent, score_details, justification = self.moteur_scoring.trouver_meilleur_agent(dossier)
        if not agent:
            return None, justification

        # 4. Créer l'attribution
        delai_heures = self.moteur_priorite.DELAIS_REGLEMENTAIRES_HEURES.get(getattr(dossier, 'type', ''), 72)
        date_limite = timezone.now() + datetime.timedelta(hours=delai_heures)

        attribution = AttributionDossier.objects.create(
            dossier=dossier,
            agent_actuel=agent.user,
            score_attribution=score_details['score_total'],
            niveau_priorite=priorite,
            source_attribution='auto',
            justification_ia=justification,
            date_limite_traitement=date_limite
        )

        # 5. Mettre à jour le statut du dossier
        dossier.assigned_agent = agent.user
        dossier.status = 'in_review'
        dossier.save(update_fields=['assigned_agent', 'status'])

        # 6. Écrire dans le journal
        JournalAttribution.objects.create(
            libelle_action="Attribution Automatique Initiale",
            dossier_id=str(dossier.id),
            agent_apres=agent.user.email,
            score_calcule=score_details['score_total'],
            justification=justification,
            metadata={"priorite": priorite}
        )

        # 7. Notification WebSocket
        self._notifier_websocket(agent.user.id, attribution.id)

        return attribution, "Attribution réussie."

    def reattribuer(self, dossier, nouvel_agent_user, source='superviseur', responsable=None, justification_manuelle=None):
        try:
            ancienne_attribution = AttributionDossier.objects.get(dossier=dossier)
            ancien_agent = ancienne_attribution.agent_actuel
            
            ancienne_attribution.ancien_agent = ancien_agent
            ancienne_attribution.agent_actuel = nouvel_agent_user
            ancienne_attribution.source_attribution = source
            ancienne_attribution.est_reattribution = True
            ancienne_attribution.responsable_attribution = responsable
            
            if justification_manuelle:
                ancienne_attribution.justification_ia = justification_manuelle
            
            ancienne_attribution.save()

            JournalAttribution.objects.create(
                libelle_action=f"Réattribution ({source})",
                dossier_id=str(dossier.id),
                agent_avant=ancien_agent.email,
                agent_apres=nouvel_agent_user.email,
                justification=justification_manuelle or "Réattribution forcée",
                responsable=responsable,
                metadata={"source": source}
            )

            self._notifier_websocket(nouvel_agent_user.id, ancienne_attribution.id)
            return ancienne_attribution, "Réattribution réussie."
        except AttributionDossier.DoesNotExist:
            # Créer l'attribution initiale si elle n'existe pas
            delai_heures = self.moteur_priorite.DELAIS_REGLEMENTAIRES_HEURES.get(getattr(dossier, 'type', ''), 72)
            date_limite = timezone.now() + datetime.timedelta(hours=delai_heures)

            attribution = AttributionDossier.objects.create(
                dossier=dossier,
                agent_actuel=nouvel_agent_user,
                score_attribution=100.0,
                niveau_priorite='moyenne',
                justification_ia=justification_manuelle or "Attribution manuelle directe",
                date_limite_traitement=date_limite,
                source_attribution=source,
                responsable_attribution=responsable
            )

            dossier.assigned_agent = nouvel_agent_user
            dossier.status = 'in_review'
            dossier.save(update_fields=['assigned_agent', 'status', 'updated_at'])

            JournalAttribution.objects.create(
                libelle_action=f"Attribution Initiale ({source})",
                dossier_id=str(dossier.id),
                agent_apres=nouvel_agent_user.email,
                justification=attribution.justification_ia,
                responsable=responsable,
                metadata={"source": source}
            )

            self._notifier_websocket(nouvel_agent_user.id, attribution.id)
            return attribution, "Attribution initiale réussie."

    def suspendre_attribution_auto(self, commune_id, duree_heures=24):
        cache_key = f"suspend_attribution_commune_{commune_id}"
        cache.set(cache_key, True, timeout=duree_heures * 3600)
        return f"Attribution automatique suspendue pour {duree_heures} heures."

    def est_attribution_suspendue(self, commune_id):
        cache_key = f"suspend_attribution_commune_{commune_id}"
        return cache.get(cache_key, False)

    def reprendre_attribution_auto(self, commune_id):
        cache_key = f"suspend_attribution_commune_{commune_id}"
        cache.delete(cache_key)

    def _notifier_websocket(self, user_id, attribution_id):
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                f"user_{user_id}",
                {
                    "type": "notification.attribution",
                    "attribution_id": attribution_id,
                    "message": "Nouveau dossier attribué"
                }
            )
