import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.test import RequestFactory
from apps.ai.views import AdminAssistantQueryView
from apps.users.models import User

# Get the civil admin for Dakar Plateau
civil_admin = User.objects.get(email="civiladmin.dakarplateau@test.local")
print(f"Testing with user: {civil_admin.email}, Role: {civil_admin.role}, Commune: {civil_admin.commune.name if civil_admin.commune else None}")

factory = RequestFactory()
request = factory.post('/api/ai/assistant-query/', {"question": "combien de demandes on a ?"}, content_type='application/json')
request.user = civil_admin

view = AdminAssistantQueryView.as_view()
response = view(request)

print(f"Status Code: {response.status_code}")
print(f"Response Data:\n{response.data.get('answer', response.data)}")
