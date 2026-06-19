import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()
from apps.dossiers.models import Dossier
from apps.documents.models import GeneratedCertificate
d = Dossier.objects.filter(type='residence_certificate').last()
if d:
    print('Dossier ID:', d.id, d.status)
    print('Dossier reference:', d.reference)
    cert = GeneratedCertificate.objects.filter(dossier=d).first()
    print('Cert:', cert)
    if cert:
        print('PDF:', cert.pdf_file)
else:
    print('None')
