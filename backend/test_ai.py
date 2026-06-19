import sys
from apps.ai.views import AdminAssistantQueryView
from apps.users.models import User
from rest_framework.test import APIRequestFactory, force_authenticate

factory = APIRequestFactory()
request = factory.post('/api/ai/admin-assistant/', {'question': 'bonjour', 'chat_history': []}, format='json')
try:
    user = User.objects.get(email='superadmin@test.local')
except User.DoesNotExist:
    user = User.objects.first()

force_authenticate(request, user=user)

view = AdminAssistantQueryView.as_view()
response = view(request)

print('STATUS:', response.status_code)
print('DATA:', response.data)
