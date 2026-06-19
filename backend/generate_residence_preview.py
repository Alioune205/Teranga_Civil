import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

import hashlib
from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from apps.dossiers.services.pdf_generator import _draw_residence_pdf_content

class Commune:
    name = "Keur Massar"
    region = "Dakar"

class Profile:
    date_of_birth = "11 Novembre 1985"
    place_of_birth = "Dakar"
    address = "Parcelles Assainies"

class Citizen:
    first_name = "Pape Alioune"
    last_name = "SENE"
    profile = Profile()

class Dossier:
    reference = "RES-2026-0099"
    commune = Commune()
    type = "residence_certificate"
    updated_at = None
    citizen = Citizen()
    metadata = {
        'prenoms_requerant': 'Pape Alioune',
        'nom_requerant': 'SENE',
        'date_naissance': '11 Novembre 1985',
        'lieu_naissance': 'Dakar',
        'adresse': 'Parcelles Assainies',
        'quartier': 'Unité 15',
        'date_installation': 'Janvier 2010'
    }

class Officier:
    full_name = "Khadija FAYE"

dossier = Dossier()
officier = Officier()
timbre_ref = "TF-RES-555X-111"
cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"

qr = qrcode.QRCode(version=1, box_size=10, border=1)
qr.add_data("https://teranga-civil.sn/verify/residence")
qr.make(fit=True)
img_qr = qr.make_image(fill_color="black", back_color="white")
qr_buffer = BytesIO()
img_qr.save(qr_buffer, format="PNG")
qr_buffer.seek(0)
qr_image_reader = ImageReader(qr_buffer)

buffer = BytesIO()
pagesize = landscape(A4)
p = canvas.Canvas(buffer, pagesize=pagesize)
width, height = pagesize

_draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

p.showPage()
p.save()

pdf_path = 'certificat_residence_keur_massar_officiel_v9.pdf'
with open(pdf_path, 'wb') as f:
    f.write(buffer.getvalue())

import fitz
doc = fitz.open(pdf_path)
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
png_path = 'C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_keur_massar_officiel_v9.png'
pix.save(png_path)
print("Généré:", png_path)
