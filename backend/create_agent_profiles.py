import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.users.models import User
from apps.etat_civil.models_attribution import ProfilAgent

agents = User.objects.filter(role='agent')

count = 0
for agent in agents:
    profil, created = ProfilAgent.objects.get_or_create(
        user=agent,
        defaults={
            'disponibilite': True,
            'charge_maximale': 10,
            'specialites': ['naissance', 'mariage', 'deces', 'residence', 'generique']
        }
    )
    if created:
        count += 1
        print(f"Créé profil agent pour {agent.email}")
    else:
        # Update existing to have some defaults just in case
        profil.disponibilite = True
        profil.specialites = ['naissance', 'mariage', 'deces', 'residence', 'generique']
        profil.save()

print(f"Terminé. {count} profils créés sur {agents.count()} agents existants.")
