from django.core.management.base import BaseCommand
from apps.dossiers.models import Dossier
from apps.documents.models import GeneratedCertificate

class Command(BaseCommand):
    def handle(self, *args, **kwargs):
        d = Dossier.objects.last()
        c = GeneratedCertificate.objects.filter(dossier=d).first()
        if c:
            print("File:", c.pdf_file.name)
            try:
                f = c.pdf_file.open('rb')
                print("Size:", len(f.read()))
                f.close()
            except Exception as e:
                print("Error opening:", e)
        else:
            print("No cert")
