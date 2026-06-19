from django.core.management.base import BaseCommand
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.communes.models import Commune
import random

class Command(BaseCommand):
    help = 'Crée 10 dossiers avec citoyen et commune renseignés'

    def handle(self, *args, **kwargs):
        commune = Commune.objects.first()
        if not commune:
            self.stdout.write(self.style.ERROR('Aucune commune trouvée. Créez-en une d\'abord.'))
            return

        citoyen, _ = User.objects.get_or_create(
            email="citoyen_test_seed@test.sn",
            defaults={"first_name": "Citoyen", "last_name": "Test", "role": "citizen"}
        )

        types = ['extrait_naissance', 'mariage', 'deces', 'residence', 'legalisation']

        for i in range(10):
            dossier = Dossier.objects.create(
                type=random.choice(types),
                status=Dossier.Status.SUBMITTED,
                citizen=citoyen,
                commune=commune
            )
            self.stdout.write(self.style.SUCCESS(f'Dossier créé: {dossier.id} ({dossier.type})'))
        
        self.stdout.write(self.style.SUCCESS('10 dossiers créés avec succès.'))
