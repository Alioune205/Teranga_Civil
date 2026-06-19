import sys
import os
import django
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

def _draw_secure_timbre(p, x, y, reference):
    VERT = HexColor('#00853F')
    ROUGE = HexColor('#E31B23')
    NOIR = HexColor('#000000')
    p.saveState()
    stamp_width = 4 * cm
    stamp_height = 2.2 * cm
    p.setFillColor(HexColor('#FFFFF0'))
    p.setStrokeColor(VERT)
    p.setLineWidth(1.5)
    p.roundRect(x, y, stamp_width, stamp_height, 4, stroke=1, fill=1)
    p.setStrokeColor(HexColor('#E0F0E0'))
    p.setLineWidth(0.5)
    for i in range(0, int(stamp_width), 5):
        p.line(x + i, y, x + i, y + stamp_height)
    p.setFillColor(VERT)
    p.setFont("Helvetica-Bold", 7)
    p.drawCentredString(x + stamp_width / 2, y + 1.6 * cm, "TIMBRE FISCAL ÉLECTRONIQUE")
    p.setFillColor(ROUGE)
    p.setFont("Helvetica-Bold", 12)
    p.drawCentredString(x + stamp_width / 2, y + 0.9 * cm, "500 FCFA")
    p.setFillColor(NOIR)
    p.setFont("Courier-Bold", 6)
    p.drawCentredString(x + stamp_width / 2, y + 0.3 * cm, f"Réf: {reference}")
    p.restoreState()

class Commune:
    name = "Keur massar"
    region = "Dakar"

class Dossier:
    reference = "MAR-2026-0012"
    commune = Commune()
    type = "marriage_certificate"
    updated_at = None
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

def _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    NOIR = HexColor('#000000')
    VERT = HexColor('#00853F')
    metadata = dossier.metadata or {}
    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"
    region_name = dossier.commune.region if dossier.commune and dossier.commune.region else "DAKAR"
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"
    registre_no = metadata.get('registre_marriage') or metadata.get('registre', 'N/A')
    annee_marriage = metadata.get('annee_marriage', 'N/A')
    style_normal = ParagraphStyle(name='Normal', fontName='Helvetica', fontSize=12, leading=16)
    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2 * cm, height - 2 * cm, f"REGION DE {region_name.upper()}")
    p.drawString(2 * cm, height - 2.5 * cm, "VILLE DE DAKAR")
    p.drawString(2 * cm, height - 3 * cm, "COMMUNE D'ARRONDISSEMENT")
    p.drawString(2 * cm, height - 3.5 * cm, f"DE {commune_name.upper()}")
    p.drawString(2 * cm, height - 4 * cm, "CENTRE D'ÉTAT CIVIL")
    p.setFont("Helvetica-Bold", 10)
    p.drawString(14 * cm, height - 2 * cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica", 10)
    p.drawString(14 * cm, height - 2.5 * cm, "Un Peuple - Un But - Une Foi")
    y_reg = height - 6.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2 * cm, y_reg, f"Registre N° {registre_no}")
    p.setFont("Helvetica", 11)
    p.drawString(2 * cm, y_reg - 0.7 * cm, f"L'an {annee_marriage},")
    p.drawString(2 * cm, y_reg - 1.4 * cm, "Date d'enregistrement non précisée.")
    y_titre = height - 9.5 * cm
    p.setFont("Helvetica-Bold", 16)
    p.drawCentredString(width / 2, y_titre, "CERTIFICAT DE MARIAGE CONSTATÉ")
    y_body = y_titre - 1.5 * cm
    para_intro = Paragraph(
        f"Nous, <b>{officier_name}</b>, Officier d'État civil du <b>CENTRE D'ÉTAT CIVIL DE {commune_name.upper()}</b>, certifions à tous ceux "
        "qu'il appartiendra que :", style_normal)
    para_intro.wrap(width - 4 * cm, 5 * cm)
    para_intro.drawOn(p, 2 * cm, y_body - para_intro.height)
    y_body -= para_intro.height + 0.8 * cm
    mari_nom = metadata.get('nom_epoux', 'Nom non précisé')
    mari_prof = metadata.get('profession_epoux', 'Non précisée')
    mari_domicile = metadata.get('domicile_epoux', 'Non précisé')
    mari_date_naiss = metadata.get('date_naissance_epoux', 'Non précisée')
    mari_lieu_naiss = metadata.get('lieu_naissance_epoux', 'Non précisé')
    mari_pere = metadata.get('prenom_pere_epoux', 'Non précisé')
    mari_mere = metadata.get('prenom_mere_epoux', 'Non précisé')
    mari_text = (
        f"<b>Monsieur {mari_nom},</b><br/>"
        f"Profession : <b>{mari_prof}</b>, domicilié à <b>{mari_domicile}</b>,<br/>"
        f"Né le {mari_date_naiss} à {mari_lieu_naiss},<br/>"
        f"Fils de <b>{mari_pere}</b> et de <b>{mari_mere}</b>,<br/>"
        "D'une part,"
    )
    para_mari = Paragraph(mari_text, style_normal)
    para_mari.wrap(width - 4 * cm, 5 * cm)
    para_mari.drawOn(p, 2 * cm, y_body - para_mari.height)
    y_body -= para_mari.height + 0.5 * cm
    p.drawString(2 * cm, y_body, "Et")
    y_body -= 0.8 * cm
    epouse_nom = metadata.get('nom_epouse', 'Nom non précisé')
    epouse_prof = metadata.get('profession_epouse', 'Non précisée')
    epouse_domicile = metadata.get('domicile_epouse', 'Non précisée')
    epouse_date_naiss = metadata.get('date_naissance_epouse', 'Non précisée')
    epouse_lieu_naiss = metadata.get('lieu_naissance_epouse', 'Non précisé')
    epouse_pere = metadata.get('prenom_pere_epouse', 'Non précisé')
    epouse_mere = metadata.get('prenom_mere_epouse', 'Non précisé')
    epouse_text = (
        f"<b>Mademoiselle {epouse_nom},</b><br/>"
        f"Profession : <b>{epouse_prof}</b>, domiciliée à <b>{epouse_domicile}</b>,<br/>"
        f"Née le <b>{epouse_date_naiss}</b> à {epouse_lieu_naiss},<br/>"
        f"Fille de <b>{epouse_pere}</b> et de <b>{epouse_mere}</b>,<br/>"
        "D'autre part,"
    )
    para_epouse = Paragraph(epouse_text, style_normal)
    para_epouse.wrap(width - 4 * cm, 5 * cm)
    para_epouse.drawOn(p, 2 * cm, y_body - para_epouse.height)
    y_body -= para_epouse.height + 0.8 * cm
    date_marriage = metadata.get('date_marriage', 'Non précisée')
    option = metadata.get('option_souscrite', 'Monogamie')
    regime = metadata.get('regime_matrimonial', 'séparation des biens')
    concl_text = (
        f"Ont contracté mariage entre eux selon la coutume, <b>le {date_marriage}</b>,<br/>"
        f"Option souscrite : <b>{option}</b>,<br/>"
        f"Et que ce mariage a été enregistré par nous sur leur demande le {date_marriage} à {region_name.capitalize()},<br/>"
        f"Régime matrimonial choisi : <b>{regime}</b>."
    )
    para_concl = Paragraph(concl_text, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)
    y_body -= para_concl.height + 1.2 * cm
    p.setFont("Helvetica", 11)
    p.drawString(2 * cm, y_body, "En foi de quoi, nous avons délivré le présent certificat pour servir et valoir ce que de droit.")
    
    # ======= CORRECTION DU CHEVAUCHEMENT =======
    # On force seal_y à être au minimum à 5 cm du bas pour ne pas toucher le QR Code
    seal_y = max(5.0 * cm, y_body - 3 * cm)
    
    from datetime import datetime
    date_str = dossier.updated_at.strftime("%d/%m/%Y") if dossier.updated_at else datetime.now().strftime("%d/%m/%Y")
    p.setFont("Helvetica-Bold", 11)
    p.drawString(12 * cm, seal_y + 3 * cm, "L'Officier de l'Etat Civil")
    p.setFont("Helvetica", 11)
    p.drawString(12 * cm, seal_y + 2.5 * cm, f"Fait à {commune_name.capitalize()}, le {date_str}")
    
    if timbre_ref:
        _draw_secure_timbre(p, 2 * cm, seal_y, timbre_ref)
        
    sig_x = width - 4 * cm
    if signature_path and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), sig_x - 1*cm, seal_y - 0.5*cm, width=4*cm, height=2*cm, mask='auto')
    if cachet_nominal_path and os.path.exists(cachet_nominal_path):
        nom_x = sig_x - 4 * cm
        p.drawImage(ImageReader(cachet_nominal_path), nom_x, seal_y, width=3.5*cm, height=1.5*cm, mask='auto')
    if cachet_path and os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), 8 * cm, seal_y - 1*cm, width=4.5*cm, height=4.5*cm, mask='auto')
        
    qr_y = 1.5 * cm
    if qr_image_reader:
        qr_size = 2.5 * cm
        qr_x = 2 * cm
        p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
        p.setFont("Helvetica", 7)
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.3 * cm, "Scannez pour vérifier l'authenticité")

def generate():
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
    _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    p.showPage()
    p.save()
    with open('certificat_mariage_keur_massar_officiel_v2.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_mariage_keur_massar_officiel_v2.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_mariage_keur_massar_officiel_v2.png')
