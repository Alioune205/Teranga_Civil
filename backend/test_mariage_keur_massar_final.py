import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from django.conf import settings

from apps.dossiers.services.pdf_generator import _draw_mariage_pdf_content

class CommuneMock:
    name = "Keur Massar"
    region = "Dakar"
    department = "Keur Massar"
    nom_officier_etat_civil = "Khadija FAYE"

class DossierMock:
    reference = "MAR-2026-0089"
    type = "marriage_certificate"
    commune = CommuneMock()
    updated_at = None
    created_at = None
    metadata = {
        'registre_marriage': '142',
        'annee_marriage': 'deux mille vingt-six',
        'nom_epoux': 'NDIAYE',
        'prenom_epoux': 'Amadou',
        'profession_epoux': 'Ingénieur',
        'domicile_epoux': 'Keur Massar',
        'date_naissance_epoux': '12/04/1990',
        'lieu_naissance_epoux': 'Dakar',
        'prenom_pere_epoux': 'Moussa',
        'nom_pere_epoux': 'NDIAYE',
        'prenom_mere_epoux': 'Fatou',
        'nom_mere_epoux': 'SOW',
        'nom_epouse': 'DIOP',
        'prenom_epouse': 'Awa',
        'profession_epouse': 'Commerçante',
        'domicile_epouse': 'Pikine',
        'date_naissance_epouse': '05/08/1995',
        'lieu_naissance_epouse': 'Pikine',
        'prenom_pere_epouse': 'Oumar',
        'nom_pere_epouse': 'DIOP',
        'prenom_mere_epouse': 'Aminata',
        'nom_mere_epouse': 'FALL',
        'date_marriage': '15/06/2026',
        'option_souscrite': 'Monogamie',
        'regime_matrimonial': 'Séparation des biens',
        'ville': 'Keur Massar',
        'centre_nom': 'Keur Massar',
        'date_enregistrement': '15/06/2026',
        'lieu_enregistrement': 'Keur Massar',
        'officier_nom': 'Khadija FAYE'
    }

class OfficierMock:
    full_name = "Khadija FAYE"

def generate_test_pdf():
    dossier = DossierMock()
    officier = OfficierMock()
    timbre_ref = "TF-MAR-99X2"
    
    # Chemins vers les assets
    # Fallback to text if missing
    cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
    cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
    signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"
    
    if not os.path.exists(cachet_path):
        cachet_path = ''
    if not os.path.exists(cachet_nominal_path):
        cachet_nominal_path = ''
    if not os.path.exists(signature_path):
        signature_path = ''

    # QR Code
    qr = qrcode.QRCode(version=1, box_size=10, border=1)
    qr.add_data(f"https://teranga-civil.sn/verify/{dossier.reference}")
    qr.make(fit=True)
    img_qr = qr.make_image(fill_color="black", back_color="white")
    qr_buffer = BytesIO()
    img_qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    qr_image_reader = ImageReader(qr_buffer)

    buffer = BytesIO()
    width, height = A4
    p = canvas.Canvas(buffer, pagesize=A4)
    
    # Génération du contenu
    _draw_mariage_pdf_content(
        p, width, height, dossier, officier, timbre_ref,
        cachet_path, signature_path, cachet_nominal_path, qr_image_reader
    )
    
    p.showPage()
    p.save()
    
    output_path = 'certificat_mariage_keur_massar.pdf'
    with open(output_path, 'wb') as f:
        f.write(buffer.getvalue())
        
    print(f"PDF généré avec succès : {os.path.abspath(output_path)}")

if __name__ == '__main__':
    generate_test_pdf()
