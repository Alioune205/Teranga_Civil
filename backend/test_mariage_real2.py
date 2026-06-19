import sys
import os
import django

sys.path.append(r"c:\Users\senep\Desktop\Teranga-Civil-Developpe\backend")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
django.setup()

import hashlib
from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER

# Stub classes for Dossier and Officier
class Commune:
    name = "Keur massar"
    region = "Dakar"

class Dossier:
    reference = "MAR-2026-0012"
    commune = Commune()
    updated_at = None
    type = "marriage_certificate"
    metadata = {
        'registre_marriage': '179',
        'annee_marriage': 'deux mille vingt-quatre',
        'nom_epoux': 'Barka KOITA',
        'profession_epoux': 'Commerçant',
        'domicile_epoux': 'Point-E',
        'date_naissance_epoux': '11 Novembre 1979',
        'lieu_naissance_epoux': 'Dakar',
        'prenom_pere_epoux': 'Harouna KOITA',
        'prenom_mere_epoux': 'Coumba SOW',
        'nom_epouse': 'Fatou SECK',
        'profession_epouse': 'Ménagère',
        'domicile_epouse': 'Point-E',
        'date_naissance_epouse': '20 Février 1999',
        'lieu_naissance_epouse': 'Lambaye',
        'prenom_pere_epouse': 'Ngora SECK',
        'prenom_mere_epouse': 'Soukeye NDIAYE',
        'date_marriage': '31 Octobre 2024',
        'option_souscrite': 'Monogamie',
        'regime_matrimonial': 'séparation des biens'
    }

class Officier:
    full_name = "Oumou Sy"

from apps.dossiers.services.pdf_generator import _draw_mariage_pdf_content, _draw_secure_timbre

def generate():
    dossier = Dossier()
    from datetime import datetime
    dossier.updated_at = datetime.now()
    officier = Officier()
    timbre_ref = "TF-894A-B823"
    
    cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
    cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
    signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"
    
    # Generate QR
    qr = qrcode.QRCode(version=1, box_size=10, border=1)
    qr.add_data("https://teranga-civil.sn/verify/123456")
    qr.make(fit=True)
    img_qr = qr.make_image(fill_color="black", back_color="white")
    qr_buffer = BytesIO()
    img_qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    qr_image_reader = ImageReader(qr_buffer)

    buffer = BytesIO()
    pagesize = A4
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    
    # We need to monkey-patch _draw_secure_timbre if it's imported locally
    import apps.dossiers.services.pdf_generator as pdf_gen
    pdf_gen._draw_secure_timbre = _draw_secure_timbre

    _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    p.showPage()
    p.save()
    
    with open('certificat_mariage_keur_massar.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_mariage_keur_massar.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_mariage_keur_massar.png')
