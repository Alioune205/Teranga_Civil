import os
import sys

from apps.dossiers.models import Dossier
from apps.dossiers.services.pdf_generator import generate_signed_certificate
from apps.users.models import User
from apps.documents.models import GeneratedCertificate

# Take any approved dossier
birth = Dossier.objects.filter(type='birth_certificate', status__in=['approved', 'completed']).first()
death = Dossier.objects.filter(type='death_certificate', status__in=['approved', 'completed']).first()
marriage = Dossier.objects.filter(type='marriage_certificate', status__in=['approved', 'completed']).first()

officier = User.objects.filter(role='officier').first()

if birth:
    GeneratedCertificate.objects.filter(dossier=birth).delete()
    generate_signed_certificate(birth, officier)
    print("Generated birth")
if death:
    GeneratedCertificate.objects.filter(dossier=death).delete()
    generate_signed_certificate(death, officier)
    print("Generated death")
if marriage:
    GeneratedCertificate.objects.filter(dossier=marriage).delete()
    generate_signed_certificate(marriage, officier)
    print("Generated marriage")

print("Done")
