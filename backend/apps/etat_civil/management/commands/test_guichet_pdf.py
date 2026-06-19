from django.core.management.base import BaseCommand
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.dossiers.services.pdf_generator import generate_signed_certificate
import traceback

class Command(BaseCommand):
    def handle(self, *args, **kwargs):
        try:
            d = Dossier.objects.filter(citoyen_guichet__isnull=False).last()
            print('Testing dossier:', d.reference)
            u = User.objects.first()
            cert = generate_signed_certificate(d, officier=u)
            print('Success!', cert.pdf_file.name)
        except Exception as e:
            traceback.print_exc()
