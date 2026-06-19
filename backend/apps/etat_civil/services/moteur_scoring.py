import datetime
from django.utils import timezone
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier

class MoteurScoring:
    MAPPING_DOSSIER_SPECIALITE = {
        'extrait_naissance': 'naissance',
        'declaration_naissance': 'naissance',
        'mariage': 'mariage',
        'deces': 'deces',
        'legalisation': 'legalisation',
        'certificat_residence': 'residence',
        'jugement_suppletif': 'juridique'
    }

    def __init__(self):
        pass

    def calculer_score_agent(self, profil_agent, dossier):
        """Calcule un score détaillé de 0 à 100 pour un agent."""
        
        # 1. Disponibilité (25%) : ratio charge actuelle / charge maximale, inversé
        charge_actuelle = AttributionDossier.objects.filter(
            agent_actuel=profil_agent.user,
            dossier__status__in=['soumis', 'in_review']  # En supposant que le statut est stocké ainsi
        ).count()
        charge_max = max(1, profil_agent.charge_maximale)
        ratio_charge = min(charge_actuelle / charge_max, 1.0)
        score_dispo = (1.0 - ratio_charge) * 100

        # 2. Compétence métier (25%) : correspondance
        dossier_type = getattr(dossier, 'type', None) # Suppose que 'type' existe
        specialite_requise = self.MAPPING_DOSSIER_SPECIALITE.get(dossier_type, 'generique')
        score_comp = 100 if specialite_requise in profil_agent.specialites else 0

        # 3. Performance historique (20%)
        score_perf = (profil_agent.taux_reussite + profil_agent.taux_respect_delais) / 2

        # 4. Rapidité (15%) : temps moyen normalisé (ex: <10m = 100%, 60m = 0%)
        temps = profil_agent.temps_moyen_traitement
        if temps <= 10:
            score_rap = 100
        elif temps >= 60:
            score_rap = 0
        else:
            score_rap = 100 - ((temps - 10) * 2) # baisse linéaire

        # 5. Charge du jour (15%)
        today = timezone.now().date()
        charge_jour = AttributionDossier.objects.filter(
            agent_actuel=profil_agent.user,
            date_attribution__date=today
        ).count()
        # Normalisation : 0 dossiers = 100, >10 dossiers = 0
        score_jour = max(0, 100 - (charge_jour * 10))

        # Pondération finale
        score_final = (
            score_dispo * 0.25 +
            score_comp * 0.25 +
            score_perf * 0.20 +
            score_rap * 0.15 +
            score_jour * 0.15
        )

        return {
            'score_total': round(score_final, 2),
            'details': {
                'disponibilite': round(score_dispo, 2),
                'competence': round(score_comp, 2),
                'performance': round(score_perf, 2),
                'rapidite': round(score_rap, 2),
                'charge_jour': round(score_jour, 2)
            },
            'raw': {
                'charge_actuelle': charge_actuelle,
                'temps_moyen': temps
            }
        }

    def _generer_justification(self, profil_agent, score_data):
        nom = getattr(profil_agent.user, 'full_name', profil_agent.user.email)
        score_perf = score_data['details']['performance']
        temps = score_data['raw']['temps_moyen']
        
        if score_data['details']['disponibilite'] > 80:
            dispo_text = "dispose actuellement de la charge la plus faible"
        else:
            dispo_text = "présente une disponibilité adéquate"

        return (f"Le dossier a été attribué à {nom} car il/elle possède un "
                f"score de performance historique de {score_perf}%, traite "
                f"les demandes en moyenne en {temps} minutes et "
                f"{dispo_text} parmi les agents disponibles.")

    def trouver_meilleur_agent(self, dossier):
        agents_actifs = ProfilAgent.objects.filter(
            user__is_active=True,
            user__is_dispatch_eligible=True,
            user__is_on_break=False,
            disponibilite=True,
            user__commune=dossier.commune
        )

        meilleur_agent = None
        meilleur_score = -1
        meilleur_details = None

        for profil in agents_actifs:
            resultat = self.calculer_score_agent(profil, dossier)
            if resultat['score_total'] > meilleur_score:
                meilleur_score = resultat['score_total']
                meilleur_agent = profil
                meilleur_details = resultat

        if meilleur_agent:
            justification = self._generer_justification(meilleur_agent, meilleur_details)
            return meilleur_agent, meilleur_details, justification

        return None, None, "Aucun agent disponible trouvé."
