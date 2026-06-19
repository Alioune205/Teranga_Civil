import os
import django
import random
from datetime import timedelta
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.users.models import User
from apps.dossiers.models import Dossier
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier
from apps.etat_civil.services.service_attribution import ServiceAttribution

def seed_data():
    print("=== Début du Seeding ===")

    # 1. Création de faux agents
    agents_data = [
        {"email": "agent1@terangacivil.sn", "nom": "Aissatou Diallo", "specialites": ["naissance", "mariage"], "charge": 10},
        {"email": "agent2@terangacivil.sn", "nom": "Mamadou Ndiaye", "specialites": ["deces", "residence"], "charge": 8},
        {"email": "agent3@terangacivil.sn", "nom": "Fatou Fall", "specialites": ["legalisation", "juridique"], "charge": 12},
    ]

    agents_crees = []
    for data in agents_data:
        user, created = User.objects.get_or_create(
            email=data["email"],
            defaults={
                "first_name": data["nom"].split()[0],
                "last_name": data["nom"].split()[1],
                "is_active": True,
                "role": "agent"
            }
        )
        if created:
            user.set_password("Passer123!")
            user.save()
            print(f"User {user.email} créé.")

        profil, p_created = ProfilAgent.objects.get_or_create(
            user=user,
            defaults={
                "specialites": data["specialites"],
                "charge_maximale": data["charge"],
                "taux_reussite": random.randint(70, 99),
                "taux_respect_delais": random.randint(60, 95),
                "temps_moyen_traitement": random.randint(10, 45)
            }
        )
        agents_crees.append(user)

    # 2. Création de faux dossiers
    types_dossiers = ['extrait_naissance', 'mariage', 'deces', 'legalisation']
    dossiers_crees = []
    
    # Trouver une commune (ou None)
    from apps.communes.models import Commune
    commune = Commune.objects.first()

    # Créer un citoyen pour le dossier
    citoyen, _ = User.objects.get_or_create(
        email="citoyen@test.sn",
        defaults={"first_name": "Test", "last_name": "Citoyen", "role": "citoyen"}
    )

    for i in range(10):
        dossier = Dossier.objects.create(
            type=random.choice(types_dossiers),
            status='soumis',
            citizen=citoyen,
            commune=commune
        )
        # Hack pour simuler des retards sur certains dossiers
        if i % 3 == 0:
            Dossier.objects.filter(id=dossier.id).update(created_at=timezone.now() - timedelta(days=2))
        
        dossiers_crees.append(dossier)
        print(f"Dossier {dossier.id} ({dossier.type}) créé.")

    # 3. Attribution via le service
    print("\nLancement du Moteur d'Attribution...")
    service = ServiceAttribution()
    
    # On rafraichit de la BDD pour avoir les bonnes dates
    dossiers_crees = Dossier.objects.filter(id__in=[d.id for d in dossiers_crees])

    for dossier in dossiers_crees:
        attr, msg = service.attribuer(dossier)
        if attr:
            print(f"OK: Attribue a {attr.agent_actuel.email} (Score: {attr.score_attribution:.1f}, Priorite: {attr.niveau_priorite})")
        else:
            print(f"ECHEC pour {dossier.id}: {msg}")

    print("\n=== Seeding Terminé ===")

if __name__ == '__main__':
    seed_data()
