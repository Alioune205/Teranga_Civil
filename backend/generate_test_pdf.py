import os
import django
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from datetime import datetime

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.dossiers.services.pdf_generator import _draw_residence_pdf_content

class MockProfile:
    date_of_birth = "01/01/1980"
    place_of_birth = "Dakar"
    address = "Parcelles Assainies Unité 15"

class MockCitizen:
    first_name = "Mamadou"
    last_name = "Diop"
    profile = MockProfile()

class MockCommune:
    name = "Parcelles Assainies"
    region = "Dakar"

class MockDossier:
    type = 'residence_certificate'
    reference = "RES-2026-0001"
    commune = MockCommune()
    citizen = MockCitizen()
    updated_at = datetime.now()
    metadata = {
        'prenoms_requerant': 'Mamadou',
        'nom_requerant': 'Diop',
        'date_naissance': '12 Mai 1985',
        'lieu_naissance': 'Dakar',
        'adresse': 'Villa 123, Unité 15, Parcelles Assainies',
        'quartier': 'Unité 15',
        'date_installation': '01 Janvier 2010'
    }

def generate():
    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    dossier = MockDossier()
    
    _draw_residence_pdf_content(
        p, width, height, dossier, officier=None, timbre_ref="12345ABC", 
        cachet_path=None, signature_path=None, cachet_nominal_path=None, qr_image_reader=None
    )
    p.showPage()
    p.save()
    with open('certificat_residence_test.pdf', 'wb') as f:
        f.write(buffer.getvalue())
    print("PDF saved as certificat_residence_test.pdf")

generate()
