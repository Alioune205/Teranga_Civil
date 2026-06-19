import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from django.test import Client
from apps.users.models import User

client = Client(SERVER_NAME='localhost')
# Get a civil_admin_supervisor
admin = User.objects.filter(role='civil_admin_supervisor').first()

print(f"Testing with user: {admin.email} (Role: {admin.role})")
client.force_login(admin)

response = client.post('/api/ai/assistant-query/', {
    "question": "Combien de naissances cette semaine ?"
}, content_type='application/json')

print("Status Code:", response.status_code)
try:
    print("Response JSON:", response.json())
except:
    print("Response Content:", response.content.decode('utf-8'))
