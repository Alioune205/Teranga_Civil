from django.core.management.base import BaseCommand
from rest_framework.test import APIClient
from django.test import RequestFactory
from apps.etat_civil.models_citoyen import Citoyen
from apps.users.models import User

class Command(BaseCommand):
    help = 'Test Guichet endpoint'

    def handle(self, *args, **kwargs):
        citoyen = Citoyen.objects.first()
        user = User.objects.first()
        
        client = APIClient()
        client.force_authenticate(user=user)
        
        try:
            response = client.post(f'/api/citoyens/{citoyen.id}/guichet/', {
                'type_document': 'birth_certificate',
                'motif': '',
                'paiement_mode': 'Espèces',
                'montant': 1000
            }, format='json', SERVER_NAME='localhost')
            print("POST STATUS:", response.status_code)
            
            if response.status_code == 201:
                pdf_url = response.data['pdf_url']
                print("PDF URL:", pdf_url)
                
                pdf_response = client.get(pdf_url, SERVER_NAME='localhost')
                print("GET PDF STATUS:", pdf_response.status_code)
                if pdf_response.status_code == 500:
                    import traceback
                    print("Response Context:", getattr(pdf_response, 'context', None))
                    print("Response Content:", pdf_response.content)
        except Exception as e:
            import traceback
            traceback.print_exc()
