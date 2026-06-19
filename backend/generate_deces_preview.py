import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from apps.dossiers.services.pdf_generator import _draw_deces_pdf_content

class Commune:
    name = "Keur Massar"
    region = "Dakar"

class Dossier:
    reference = "DEC-2026-0045"
    commune = Commune()
    type = "death_certificate"
    updated_at = None
    metadata = {
        'nom_defunt': 'SARR',
        'prenom_defunt': 'Amadou',
        'sexe_defunt': 'M',
        'date_naissance_defunt': '12/05/1950',
        'lieu_naissance_defunt': 'Rufisque',
        'date_deces': '10 Juin 2026',
        'heure_deces': '14h30',
        'lieu_deces': 'Hôpital de Keur Massar',
        'nationalite_defunt': 'Sénégalaise',
        'profession_defunt': 'Retraité',
        'adresse_defunt': 'Quartier Darou, Keur Massar',
        'nom_declarant': 'Mamadou SARR',
        'lien_declarant': 'Fils',
        'cni_declarant': '1 234 1980 56789'
    }

class Officier:
    full_name = "Khadija FAYE"

dossier = Dossier()
officier = Officier()
timbre_ref = "TF-112B-X890"
cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"

qr = qrcode.QRCode(version=1, box_size=10, border=1)
qr.add_data("https://teranga-civil.sn/verify/DEC-2026-0045")
qr.make(fit=True)
img_qr = qr.make_image(fill_color="black", back_color="white")
qr_buffer = BytesIO()
img_qr.save(qr_buffer, format="PNG")
qr_buffer.seek(0)
qr_image_reader = ImageReader(qr_buffer)

buffer = BytesIO()
p = canvas.Canvas(buffer, pagesize=A4)
width, height = A4
_draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

p.showPage()
p.save()

pdf_path = 'certificat_deces_keur_massar_officiel_v2.pdf'
with open(pdf_path, 'wb') as f:
    f.write(buffer.getvalue())

import fitz
doc = fitz.open(pdf_path)
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
png_path = 'C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_deces_keur_massar_officiel_v2.png'
pix.save(png_path)
print("Généré:", png_path)
