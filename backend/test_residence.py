import os
import django
from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
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
    p.drawCentredString(x + stamp_width / 2, y + 0.8 * cm, "200 FRANCS")
    p.setFillColor(NOIR)
    p.setFont("Courier-Bold", 6)
    p.drawCentredString(x + stamp_width / 2, y + 0.2 * cm, f"Réf: {reference}")
    p.restoreState()

class Commune:
    name = "Keur massar"
    region = "Dakar"

class Dossier:
    reference = "RES-2026-0089"
    commune = Commune()
    type = "residence_certificate"
    updated_at = None
    metadata = {
        'nom_demandeur': 'Mamadou Diop',
        'date_naissance_demandeur': '12 Mai 1985',
        'lieu_naissance_demandeur': 'Dakar',
        'adresse_demandeur': 'Villa 123, Unité 15',
        'quartier_demandeur': 'Unité 15',
        'annee_residence': '2010',
        'numero_sd': '45',
        'numero_registre': '890'
    }

class Officier:
    full_name = "Ousmane SY"

def _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    NOIR = HexColor('#000000')
    VERT = HexColor('#00853F')
    
    metadata = dossier.metadata or {}
    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"
    region_name = dossier.commune.region if dossier.commune and dossier.commune.region else "DAKAR"
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"
    
    style_normal = ParagraphStyle(name='Normal', fontName='Helvetica', fontSize=14, leading=22, alignment=TA_CENTER)
    
    # ---------------- EN-TÊTE ----------------
    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 12)
    p.drawString(2 * cm, height - 2 * cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica", 10)
    p.drawString(2 * cm, height - 2.5 * cm, "Un Peuple - Un But - Une Foi")
    
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2 * cm, height - 3.5 * cm, f"REGION DE {region_name.upper()}")
    p.drawString(2 * cm, height - 4.0 * cm, "DEPARTEMENT DE KEUR MASSAR")
    p.drawString(2 * cm, height - 4.5 * cm, f"COMMUNE DE {commune_name.upper()}")
    
    # ---------------- TITRE ----------------
    y_titre = height - 6.5 * cm
    p.setFont("Helvetica-Bold", 24)
    p.drawCentredString(width / 2, y_titre, "CERTIFICAT DE RÉSIDENCE")
    p.setLineWidth(2)
    p.line(width / 2 - 6 * cm, y_titre - 0.3 * cm, width / 2 + 6 * cm, y_titre - 0.3 * cm)
    
    # ---------------- TEXTE CENTRAL ----------------
    y_body = y_titre - 3.0 * cm
    
    nom = metadata.get('nom_demandeur', '{nom_demandeur}')
    date_naiss = metadata.get('date_naissance_demandeur', '{date_naissance}')
    lieu_naiss = metadata.get('lieu_naissance_demandeur', '{lieu_naissance}')
    adresse = metadata.get('adresse_demandeur', '{adresse}')
    quartier = metadata.get('quartier_demandeur', '{quartier}')
    annee = metadata.get('annee_residence', '{annee_residence}')
    
    texte_central = (
        f"Nous soussigné(e) Maire de la Commune de <b>{commune_name.capitalize()}</b>, "
        f"certifions que <b>{nom}</b>, né(e) le <b>{date_naiss}</b> à <b>{lieu_naiss}</b>, "
        f"réside à <b>{adresse}</b>, au quartier <b>{quartier}</b> depuis le 01 Janvier <b>{annee}</b>."
    )
    
    para_intro = Paragraph(texte_central, style_normal)
    para_intro.wrap(width - 8 * cm, 10 * cm)
    para_intro.drawOn(p, 4 * cm, y_body - para_intro.height)
    
    # MENTION DE VALIDITÉ 3 MOIS
    y_body -= para_intro.height + 1.5 * cm
    p.setFont("Helvetica-BoldOblique", 11)
    p.drawCentredString(width / 2, y_body, "Validité : 3 mois à compter de la date de délivrance.")
    
    y_body -= 1.0 * cm
    p.setFont("Helvetica", 12)
    texte_concl = "En foi de quoi le présent certificat est délivré pour servir et valoir ce que de droit."
    p.drawCentredString(width / 2, y_body, texte_concl)
    
    # ---------------- 5 ZONES DE VALIDATION ----------------
    # Pour s'adapter au format paysage, on gère les largeurs et on décale si besoin.
    zone_y = 2.0 * cm 
    
    from datetime import datetime
    date_str = dossier.updated_at.strftime("%d/%m/%Y") if dossier.updated_at else datetime.now().strftime("%d/%m/%Y")
    
    # ZONE 1 : QR Code + Textes
    z1_x = 2.0 * cm
    qr_size = 2.5 * cm
    qr_y = zone_y + 0.8 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, z1_x + 0.5*cm, qr_y, width=qr_size, height=qr_size)
    p.setFont("Helvetica", 6)
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.2 * cm, "Scannez pour vérifier")
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.5 * cm, "l'authenticité")
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    # ZONE 2 : Timbre Fiscal
    z2_x = z1_x + 5.0 * cm
    if timbre_ref:
        _draw_secure_timbre(p, z2_x, zone_y + 0.8 * cm, timbre_ref)

    # ZONE 3 : Tampon rond (Cachet Communal)
    z3_x = z2_x + 5.0 * cm
    cachet_y = zone_y + 0.2 * cm
    if cachet_path and os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), z3_x, cachet_y, width=4.0*cm, height=4.0*cm, mask='auto')

    # ZONE 4 : Texte Officier
    z4_x = z3_x + 6.0 * cm
    text_y = zone_y + 3.5 * cm
    p.setFont("Helvetica", 11)
    p.drawCentredString(z4_x + 2.0*cm, text_y, f"Fait à {commune_name.capitalize()},")
    p.drawCentredString(z4_x + 2.0*cm, text_y - 0.5*cm, f"le {date_str}")
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(z4_x + 2.0*cm, text_y - 1.5*cm, officier_name)

    # ZONE 5 : Tampon Ovale (Nominal) + Signature manuscrite
    z5_x = z4_x + 5.0 * cm
    cachet_nom_w = 3.5 * cm
    cachet_nom_h = 1.5 * cm
    cachet_nom_y = zone_y + 1.8 * cm
    if cachet_nominal_path and os.path.exists(cachet_nominal_path):
        p.drawImage(ImageReader(cachet_nominal_path), z5_x, cachet_nom_y, width=cachet_nom_w, height=cachet_nom_h, mask='auto')
    
    sig_w = 3.5 * cm
    sig_h = 1.5 * cm
    sig_y = cachet_nom_y - sig_h - 0.2*cm
    if signature_path and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), z5_x, sig_y, width=sig_w, height=sig_h, mask='auto')

def generate():
    dossier = Dossier()
    officier = Officier()
    timbre_ref = "TF-RES-5421"
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
    pagesize = landscape(A4)
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    p.showPage()
    p.save()
    with open('certificat_residence_3_mois.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_residence_3_mois.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_3_mois.png')
