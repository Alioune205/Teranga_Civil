from django.core.management.base import BaseCommand
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.dossiers.services.pdf_generator import generate_signed_certificate

class Command(BaseCommand):
    def handle(self, *args, **kwargs):
        try:
            dossier = Dossier.objects.last()
            officier = User.objects.filter(role='super_admin').first()
            print(f"Generating for Dossier: {dossier.id}, Officier: {officier.email}")
            cert = generate_signed_certificate(dossier, officier)
            print("SUCCESS! CERT ID:", cert.id)
        except Exception as e:
            import traceback
            traceback.print_exc()
