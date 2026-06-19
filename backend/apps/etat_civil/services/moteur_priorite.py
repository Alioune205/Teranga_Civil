from django.utils import timezone
import datetime

class MoteurPriorite:
    DELAIS_REGLEMENTAIRES_HEURES = {
        'declaration_naissance': 72,
        'deces': 24,
        'mariage': 168,
        'extrait_naissance': 48,
        'certificat_residence': 48,
        'legalisation': 96,
        'jugement_suppletif': 240
    }

    def calculer_priorite(self, dossier, intervention_superviseur=False):
        """
        Calcule automatiquement le niveau de priorité d'un dossier.
        """
        now = timezone.now()
        heures_ecoulees = 0
        if dossier.created_at:
            delta = now - dossier.created_at
            heures_ecoulees = delta.total_seconds() / 3600

        dossier_type = getattr(dossier, 'type', 'inconnu')
        statut = getattr(dossier, 'status', 'soumis')
        paiement_confirme = getattr(dossier, 'paiement_confirme', False)

        # Règle 1: Urgent
        if intervention_superviseur or heures_ecoulees > 72 or dossier_type == 'deces':
            return 'urgent'

        # Règle 2: Faible (en attente de pièces)
        if statut in ['incomplet', 'attente_pieces']:
            return 'faible'

        # Règle 3: Élevé
        delai_reglementaire = self.DELAIS_REGLEMENTAIRES_HEURES.get(dossier_type, 72)
        if heures_ecoulees > 48 or paiement_confirme or delai_reglementaire < 24:
            return 'eleve'

        # Règle 4: Normal
        return 'normal'
