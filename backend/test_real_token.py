import requests
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.users.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from apps.dossiers.models import Dossier

u = User.objects.filter(role='super_admin').first()
refresh = RefreshToken.for_user(u)
token = str(refresh.access_token)

d = Dossier.objects.last()
print(f"Fetching PDF for dossier {d.id} ({d.reference})")
url = f'http://localhost:8000/api/dossiers/{d.id}/download-pdf/'

headers = {'Authorization': f'Bearer {token}'}
r = requests.get(url, headers=headers)
print("Status Code:", r.status_code)
if r.status_code == 500:
    print("Response JSON/Text:", r.text[:1000])
else:
    print("Content length:", len(r.content))
