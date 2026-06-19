import os
import django
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
    stamp_width = 3.3 * cm
    stamp_height = 2.0 * cm
    p.setFillColor(HexColor('#FFFFF0'))
    p.setStrokeColor(VERT)
    p.setLineWidth(1.5)
    p.roundRect(x, y, stamp_width, stamp_height, 4, stroke=1, fill=1)
    p.setStrokeColor(HexColor('#E0F0E0'))
    p.setLineWidth(0.5)
    for i in range(0, int(stamp_width), 5):
        p.line(x + i, y, x + i, y + stamp_height)
    p.setFillColor(VERT)
    p.setFont("Helvetica-Bold", 6)
    p.drawCentredString(x + stamp_width / 2, y + 1.5 * cm, "TIMBRE FISCAL ÉLECTRONIQUE")
    p.setFillColor(ROUGE)
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(x + stamp_width / 2, y + 0.8 * cm, "500 FCFA")
    p.setFillColor(NOIR)
    p.setFont("Courier-Bold", 6)
    p.drawCentredString(x + stamp_width / 2, y + 0.2 * cm, f"Réf: {reference}")
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
        'registre_marriage': '{numero_registre}',
        'annee_marriage': 'deux mille vingt-six',
        'nom_epoux': '{nom_epoux}',
        'profession_epoux': '{profession_epoux}',
        'domicile_epoux': '{adresse_epoux}',
        'date_naissance_epoux': '{date_naissance_epoux}',
        'lieu_naissance_epoux': '{lieu_naissance_epoux}',
        'prenom_pere_epoux': '{pere_epoux}',
        'prenom_mere_epoux': '{mere_epoux}',
        'nom_epouse': '{nom_epouse}',
        'profession_epouse': '{profession_epouse}',
        'domicile_epouse': '{adresse_epouse}',
        'date_naissance_epouse': '{date_naissance_epouse}',
        'lieu_naissance_epouse': '{lieu_naissance_epouse}',
        'prenom_pere_epouse': '{pere_epouse}',
        'prenom_mere_epouse': '{mere_epouse}',
        'date_marriage': '{date_mariage}',
        'option_souscrite': '{option_souscrite}',
        'regime_matrimonial': '{regime_matrimonial}'
    }

class Officier:
    full_name = "Khadija FAYE"

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
    
    # On gagne de la place
    y_body -= para_concl.height + 0.8 * cm
    p.setFont("Helvetica", 11)
    p.drawString(2 * cm, y_body, "En foi de quoi, nous avons délivré le présent certificat pour servir et valoir ce que de droit.")
    
    # ======= REORGANISATION EN 5 ZONES =======
    # y_body est la fin du texte.
    # On garantit que la zone des tampons (qui fait max 4.5cm de haut) se place en bas,
    # et ne chevauche pas y_body.
    zone_y = min(1.5 * cm, y_body - 4.5 * cm) 
    
    from datetime import datetime
    date_str = dossier.updated_at.strftime("%d/%m/%Y") if dossier.updated_at else datetime.now().strftime("%d/%m/%Y")
    
    # === ZONE 1 : QR Code + Textes ===
    z1_x = 1.0 * cm
    qr_size = 2.5 * cm
    qr_y = zone_y + 0.8 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, z1_x + 0.5*cm, qr_y, width=qr_size, height=qr_size)
    p.setFont("Helvetica", 6)
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.2 * cm, "Scannez pour vérifier")
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.5 * cm, "l'authenticité")
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    # === ZONE 2 : Timbre Fiscal ===
    z2_x = z1_x + 3.5 * cm
    if timbre_ref:
        _draw_secure_timbre(p, z2_x, zone_y + 0.8 * cm, timbre_ref)

    # === ZONE 3 : Tampon rond (Cachet Communal) ===
    z3_x = z2_x + 3.5 * cm
    cachet_y = zone_y + 0.2 * cm
    if cachet_path and os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), z3_x, cachet_y, width=4.0*cm, height=4.0*cm, mask='auto')

    # === ZONE 4 : Texte Officier ===
    z4_x = z3_x + 4.2 * cm
    text_y = zone_y + 3.5 * cm
    p.setFont("Helvetica", 9)
    p.drawCentredString(z4_x + 1.5*cm, text_y, f"Fait à {commune_name.capitalize()},")
    p.drawCentredString(z4_x + 1.5*cm, text_y - 0.4*cm, f"le {date_str}")
    p.setFont("Helvetica-Bold", 9)
    p.drawCentredString(z4_x + 1.5*cm, text_y - 1.2*cm, officier_name)
    p.setFont("Helvetica", 9)
    p.drawCentredString(z4_x + 1.5*cm, text_y - 1.6*cm, "Officier de l'Etat Civil")

    # === ZONE 5 : Tampon Ovale (Nominal) + Signature manuscrite ===
    z5_x = z4_x + 3.0 * cm
    # Le tampon nominal
    cachet_nom_w = 3.5 * cm
    cachet_nom_h = 1.5 * cm
    cachet_nom_y = zone_y + 1.8 * cm
    if cachet_nominal_path and os.path.exists(cachet_nominal_path):
        p.drawImage(ImageReader(cachet_nominal_path), z5_x, cachet_nom_y, width=cachet_nom_w, height=cachet_nom_h, mask='auto')
    
    # La signature EN DESSOUS (ou au-dessus) du tampon nominal pour ne pas chevaucher
    sig_w = 3.5 * cm
    sig_h = 1.5 * cm
    sig_y = cachet_nom_y - sig_h - 0.2*cm
    if signature_path and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), z5_x, sig_y, width=sig_w, height=sig_h, mask='auto')

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
    with open('certificat_mariage_keur_massar_officiel_v4.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_mariage_keur_massar_officiel_v4.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_mariage_keur_massar_officiel_v4.png')
