import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.etat_civil.models_citoyen import Citoyen
from apps.users.models import User
from django.test import RequestFactory
from apps.etat_civil.api.citoyen_views import CitoyenViewSet

citoyen = Citoyen.objects.first()
user = User.objects.first()

factory = RequestFactory()
request = factory.post('/api/citoyens/guichet/', {
    'type_document': 'birth_certificate',
    'motif': '',
    'paiement_mode': 'Espèces',
    'montant': 1000
}, format='json')
request.user = user

view = CitoyenViewSet.as_view({'post': 'guichet'})
try:
    response = view(request, pk=citoyen.id)
    print("STATUS:", response.status_code)
    print("DATA:", response.data)
except Exception as e:
    import traceback
    traceback.print_exc()
