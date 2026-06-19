import os
from celery import shared_task
from django.utils import timezone
from django.conf import settings
from apps.etat_civil.models_attribution import AttributionDossier, ProfilAgent
from apps.etat_civil.services.service_attribution import ServiceAttribution
from apps.dossiers.models import Dossier
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

@shared_task
def verifier_dossiers_en_retard():
    delai_alerte = int(os.environ.get('ATTRIBUTION_DELAI_ALERTE', 24))
    delai_reattribution = int(os.environ.get('ATTRIBUTION_DELAI_REATTRIBUTION', 48))
    
    now = timezone.now()
    service = ServiceAttribution()
    channel_layer = get_channel_layer()

    attributions_actives = AttributionDossier.objects.filter(
        dossier__status='in_review'
    )

    for attribution in attributions_actives:
        heures_ecoulees = (now - attribution.date_attribution).total_seconds() / 3600

        # Règle > 48h (Réattribution)
        if heures_ecoulees > delai_reattribution:
            if not attribution.notification_48h_envoyee:
                # Alerte superviseur (broadcast à un groupe superviseur)
                if channel_layer:
                    async_to_sync(channel_layer.group_send)(
                        "superviseurs",
                        {
                            "type": "notification.alerte",
                            "message": f"Le dossier {attribution.dossier.id} est en retard critique (>48h)."
                        }
                    )
                
                # Réattribution automatique (on choisit le meilleur agent disponible)
                nouvel_agent, _, _ = service.moteur_scoring.trouver_meilleur_agent(attribution.dossier)
                if nouvel_agent and nouvel_agent.user != attribution.agent_actuel:
                    service.reattribuer(
                        dossier=attribution.dossier,
                        nouvel_agent_user=nouvel_agent.user,
                        source='auto',
                        justification_manuelle="Délai maximum dépassé (>48h). Réattribution automatique."
                    )

                attribution.notification_48h_envoyee = True
                attribution.save(update_fields=['notification_48h_envoyee'])
                continue # passe au suivant car réattribué

        # Règle > 24h (Alerte simple)
        if heures_ecoulees > delai_alerte and not attribution.notification_24h_envoyee:
            if channel_layer:
                async_to_sync(channel_layer.group_send)(
                    f"user_{attribution.agent_actuel.id}",
                    {
                        "type": "notification.alerte",
                        "message": f"Rappel: Le dossier {attribution.dossier.id} est en attente depuis >24h."
                    }
                )
            attribution.notification_24h_envoyee = True
            attribution.save(update_fields=['notification_24h_envoyee'])


@shared_task
def recalculer_scores_agents():
    service = ServiceAttribution()
    agents = ProfilAgent.objects.filter(user__is_active=True)
    
    # On simule un dossier générique pour forcer le recalcul global
    # Le moteur a besoin d'un dossier. Créons une instance fictive ou mock.
    class DossierMock:
        type = 'generique'
    
    mock_dossier = DossierMock()
    
    for agent in agents:
        resultat = service.moteur_scoring.calculer_score_agent(agent, mock_dossier)
        agent.score_global = resultat['score_total']
        agent.save(update_fields=['score_global'])


@shared_task
def attribuer_dossier_async(dossier_id):
    try:
        dossier = Dossier.objects.get(id=dossier_id)
        if dossier.status in ['soumis', 'submitted', 'SUBMITTED']:
            service = ServiceAttribution()
            service.attribuer(dossier)
    except Dossier.DoesNotExist:
        pass
