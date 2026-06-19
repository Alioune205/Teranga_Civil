from django.core.management.base import BaseCommand
import requests
from apps.dossiers.models import Dossier
from apps.users.models import User
from rest_framework_simplejwt.tokens import RefreshToken
import traceback

class Command(BaseCommand):
    def handle(self, *args, **kwargs):
        d = Dossier.objects.last()
        u = User.objects.filter(role='super_admin').first()
        refresh = RefreshToken.for_user(u)
        token = str(refresh.access_token)
        url = f'http://localhost:8000/api/dossiers/{d.id}/download-pdf/'
        headers = {'Authorization': f'Bearer {token}'}
        print("GET", url)
        try:
            r = requests.get(url, headers=headers)
            print('Status:', r.status_code)
            if r.status_code == 500:
                print('Content:', r.text[:1000])
            else:
                print('Size:', len(r.content))
        except Exception as e:
            traceback.print_exc()
