import random
from datetime import timedelta, date
from django.core.management.base import BaseCommand
from apps.etat_civil.models_citoyen import Citoyen
from apps.communes.models import Commune
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Peuple la base de données avec des citoyens de test (Guichet/Répertoire)'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.NOTICE('Début de la création des citoyens...'))

        communes = list(Commune.objects.all())
        if not communes:
            self.stdout.write(self.style.ERROR('Aucune commune trouvée. Veuillez d\'abord exécuter seed_data pour créer des communes.'))
            return
            
        super_admin = User.objects.filter(role=User.Role.SUPER_ADMIN).first()

        citoyens_data = [
            {
                "prenom": "Alioune",
                "nom": "Sene",
                "date_naissance": date(1990, 5, 12),
                "lieu_naissance": "Dakar",
                "sexe": "M",
                "telephone": "+221775026615",
                "email": "senepapealioune@gmail.com",
                "adresse": "Cité Socabeg",
                "quartier": "Keur Massar",
                "numero_cni": "1234567890123",
            },
            {
                "prenom": "Fatou",
                "nom": "Diop",
                "date_naissance": date(1995, 8, 24),
                "lieu_naissance": "Saint-Louis",
                "sexe": "F",
                "telephone": "+221772223344",
                "email": "fatou.diop@example.com",
                "adresse": "Nord Foire",
                "quartier": "Yoff",
                "numero_cni": "2234567890123",
            },
            {
                "prenom": "Mamadou",
                "nom": "Ndiaye",
                "date_naissance": date(1985, 2, 10),
                "lieu_naissance": "Thiès",
                "sexe": "M",
                "telephone": "+221773334455",
                "email": "m.ndiaye@example.com",
                "adresse": "Médina",
                "quartier": "Médina",
                "numero_cni": "3234567890123",
            },
            {
                "prenom": "Aissatou",
                "nom": "Sow",
                "date_naissance": date(1992, 11, 5),
                "lieu_naissance": "Rufisque",
                "sexe": "F",
                "telephone": "+221774445566",
                "email": "a.sow@example.com",
                "adresse": "HLM 5",
                "quartier": "HLM",
                "numero_cni": "4234567890123",
            },
            {
                "prenom": "Cheikh",
                "nom": "Fall",
                "date_naissance": date(1988, 7, 30),
                "lieu_naissance": "Ziguinchor",
                "sexe": "M",
                "telephone": "+221775556677",
                "email": "cheikh.fall@example.com",
                "adresse": "Parcelles Assainies",
                "quartier": "Unité 15",
                "numero_cni": "5234567890123",
            },
            {
                "prenom": "Aminata",
                "nom": "Ba",
                "date_naissance": date(1998, 1, 15),
                "lieu_naissance": "Dakar",
                "sexe": "F",
                "telephone": "+221776667788",
                "email": "aminata.ba@example.com",
                "adresse": "Ouakam",
                "quartier": "Ouakam Cité",
                "numero_cni": "6234567890123",
            },
            {
                "prenom": "Ousmane",
                "nom": "Gueye",
                "date_naissance": date(1980, 4, 18),
                "lieu_naissance": "Mbour",
                "sexe": "M",
                "telephone": "+221777778899",
                "email": "ousmane.g@example.com",
                "adresse": "Mermoz",
                "quartier": "Mermoz",
                "numero_cni": "7234567890123",
            },
            {
                "prenom": "Mariama",
                "nom": "Diallo",
                "date_naissance": date(2001, 9, 22),
                "lieu_naissance": "Kaolack",
                "sexe": "F",
                "telephone": "+221778889900",
                "email": "m.diallo@example.com",
                "adresse": "Fass",
                "quartier": "Fass Delorme",
                "numero_cni": "8234567890123",
            }
        ]

        count = 0
        for data in citoyens_data:
            if not Citoyen.objects.filter(telephone=data['telephone']).exists():
                commune = random.choice(communes)
                Citoyen.objects.create(
                    **data,
                    commune=commune,
                    created_by=super_admin
                )
                count += 1
                self.stdout.write(self.style.SUCCESS(f"Créé: {data['prenom']} {data['nom']} - {data['telephone']}"))
            else:
                self.stdout.write(self.style.WARNING(f"Ignoré: Le citoyen avec le téléphone {data['telephone']} existe déjà."))

        self.stdout.write(self.style.SUCCESS(f'Opération terminée. {count} citoyens créés.'))
