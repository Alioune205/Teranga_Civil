import sys
import os
import django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.etat_civil.models import Citoyen
from apps.communes.models import Commune
from apps.dossiers.services.add_regularisation_receipt import generate_regularisation_receipt

# get a commune
commune = Commune.objects.first()

# create citizen
user = User.objects.filter(role='CITIZEN').first()

# create dossier
dossier = Dossier.objects.create(
    type=Dossier.Type.REGULARISATION,
    citizen=user,
    commune=commune,
    status=Dossier.Status.SUBMITTED,
    metadata={
        "localisation_terrain": "Parcelles Assainies Unité 15",
        "quartier_village": "Unité 15",
        "superficie": "150 m2",
        "reference_cadastrale": "TF 1234/N",
        "nom_complet_requerant": "Moussa Diop",
        "numero_cni": "1234567890123",
        "telephone": "771234567"
    }
)
dossier.save()

# Generate receipt
cert = generate_regularisation_receipt(dossier)
print("Generated PDF at:", cert.pdf_file.path)

import shutil
shutil.copy(cert.pdf_file.path, '../Recepisse_Regularisation_Test.pdf')
print("Copied to Recepisse_Regularisation_Test.pdf")
