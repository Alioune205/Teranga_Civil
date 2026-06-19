import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.authentication.models import CustomUser
from apps.dossiers.models import Dossier

agent = CustomUser.objects.filter(role='agent').first()
print(f"Agent: {agent.email}")
print(f"Dossiers assigned to agent: {Dossier.objects.filter(assigned_agent=agent).count()}")
print(f"Dossiers created by agent: {Dossier.objects.filter(created_by=agent).count() if hasattr(Dossier, 'created_by') else 'N/A'}")

# check all dossiers created at guichet
guichet_dossiers = Dossier.objects.filter(citoyen_guichet__isnull=False)
print(f"Guichet dossiers: {guichet_dossiers.count()}")
for d in guichet_dossiers:
    print(f" - {d.reference} | Agent: {d.assigned_agent.email if d.assigned_agent else 'None'} | Commune: {d.commune.name if d.commune else 'None'}")
