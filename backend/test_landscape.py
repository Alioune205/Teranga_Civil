import os
import django
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from datetime import datetime
import fitz

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.dossiers.services.pdf_generator import _draw_residence_pdf_content

class MockProfile:
    date_of_birth = "12/05/1985"
    place_of_birth = "Dakar"
    address = "Villa 123, Unité 15, Parcelles Assainies"

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
    pagesize = landscape(A4)
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    dossier = MockDossier()
    
    _draw_residence_pdf_content(
        p, width, height, dossier, officier=None, timbre_ref="TIM-999-XYZ", 
        cachet_path=None, signature_path=None, cachet_nominal_path=None, qr_image_reader=None
    )
    p.showPage()
    p.save()
    with open('certificat_residence_test.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

doc = fitz.open('certificat_residence_test.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_fictif.png')
