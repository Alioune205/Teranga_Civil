import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

import hashlib
from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from apps.dossiers.services.pdf_generator import _draw_mariage_pdf_content

class Commune:
    name = "Keur Massar"
    region = "Dakar"

class Dossier:
    reference = "MAR-2026-0012"
    commune = Commune()
    type = "marriage_certificate"
    updated_at = None
    metadata = {
        'registre_marriage': '001',
        'annee_marriage': 'deux mille vingt-six',
        
        'nom_epoux': 'NDIAYE',
        'profession_epoux': 'Ingénieur',
        'domicile_epoux': 'Dakar',
        'date_naissance_epoux': '01/01/1980',
        'lieu_naissance_epoux': 'Dakar',
        'prenom_pere_epoux': 'Moussa',
        'nom_pere_epoux': 'NDIAYE',
        'prenom_mere_epoux': 'Awa',
        'nom_mere_epoux': 'DIALLO',
        
        'nom_epouse': 'DIOP',
        'profession_epouse': 'Enseignante',
        'domicile_epouse': 'Dakar',
        'date_naissance_epouse': '02/02/1985',
        'lieu_naissance_epouse': 'Rufisque',
        'prenom_pere_epouse': 'Aliou',
        'nom_pere_epouse': 'DIOP',
        'prenom_mere_epouse': 'Fatou',
        'nom_mere_epouse': 'SARR',
        
        'date_marriage': '10 Juin 2026',
        'option_souscrite': 'Monogamie',
        'regime_matrimonial': 'Séparation de biens'
    }

class Officier:
    full_name = "Khadija FAYE"

dossier = Dossier()
officier = Officier()
timbre_ref = "TF-894A-B823"
cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"

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
_draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

p.showPage()
p.save()

pdf_path = 'certificat_mariage_keur_massar_officiel_v11.pdf'
with open(pdf_path, 'wb') as f:
    f.write(buffer.getvalue())

import fitz
doc = fitz.open(pdf_path)
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
png_path = 'C:/Users/senep/.gemini/antigravity-ide/brain/6a753687-ccec-4af2-bd12-4e87afc342c3/certificat_mariage_keur_massar_officiel_v11.png'
pix.save(png_path)
print("Généré:", png_path)
