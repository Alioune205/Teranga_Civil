import os
from io import BytesIO
import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY

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
    reference = "DEC-2026-0042"
    commune = Commune()
    type = "death_certificate"
    updated_at = None
    metadata = {
        'nom_defunt': 'NDIAYE',
        'prenom_defunt': 'Mamadou Lamine',
        'sexe_defunt': 'Masculin',
        'date_naissance_defunt': '15 Mars 1950',
        'lieu_naissance_defunt': 'Saint-Louis',
        'nationalite_defunt': 'Sénégalaise',
        'profession_defunt': 'Enseignant Retraité',
        'adresse_defunt': 'Unité 15, Keur Massar',
        'date_deces': '10 Juin 2026',
        'heure_deces': '14h30',
        'lieu_deces': 'Hôpital Militaire de Ouakam',
        'nom_declarant': 'Fatou NDIAYE',
        'lien_declarant': 'Fille',
        'cni_declarant': '1 756 1990 01234',
        'telephone_declarant': '77 123 45 67'
    }

class Officier:
    full_name = "Khadija FAYE"

def _draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    NOIR = HexColor('#000000')
    VERT = HexColor('#00853F')
    GRIS = HexColor('#EEEEEE')
    
    metadata = dossier.metadata or {}
    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"
    region_name = dossier.commune.region if dossier.commune and dossier.commune.region else "DAKAR"
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"
    
    style_normal = ParagraphStyle(name='Normal', fontName='Helvetica', fontSize=12, leading=18, alignment=TA_JUSTIFY)
    
    # ---------------- EN-TÊTE ----------------
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
    
    # ---------------- TITRE ----------------
    y_titre = height - 6.5 * cm
    p.setFont("Helvetica-Bold", 18)
    p.drawCentredString(width / 2, y_titre, "CERTIFICAT DE DÉCÈS")
    p.setLineWidth(1)
    p.line(width / 2 - 4 * cm, y_titre - 0.2 * cm, width / 2 + 4 * cm, y_titre - 0.2 * cm)
    
    # ---------------- TEXTE ADMINISTRATIF ----------------
    y_body = y_titre - 2.0 * cm
    
    nom = metadata.get('nom_defunt', '{nom_defunt}')
    prenom = metadata.get('prenom_defunt', '{prenom_defunt}')
    sexe = metadata.get('sexe_defunt', '{sexe}')
    titre = "Monsieur" if sexe.lower().startswith('m') else "Madame"
    date_naiss = metadata.get('date_naissance_defunt', '{date_naissance}')
    lieu_naiss = metadata.get('lieu_naissance_defunt', '{lieu_naissance}')
    date_deces = metadata.get('date_deces', '{date_deces}')
    heure_deces = metadata.get('heure_deces', '{heure_deces}')
    lieu_deces = metadata.get('lieu_deces', '{lieu_deces}')
    
    texte_intro = (
        f"Je soussigné(e), <b>{officier_name}</b>, Officier de l'État Civil de la Commune de "
        f"<b>{commune_name.capitalize()}</b>, certifie que :<br/><br/>"
        f"{titre} <b>{prenom} {nom}</b>, né(e) le <b>{date_naiss}</b> à <b>{lieu_naiss}</b>, "
        f"est décédé(e) le <b>{date_deces}</b> à <b>{heure_deces}</b>, à <b>{lieu_deces}</b>."
    )
    
    para_intro = Paragraph(texte_intro, style_normal)
    para_intro.wrap(width - 4 * cm, 10 * cm)
    para_intro.drawOn(p, 2 * cm, y_body - para_intro.height)
    y_body -= para_intro.height + 1.5 * cm
    
    # ---------------- TABLEAU RECAPITULATIF ----------------
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2 * cm, y_body, "Informations Complémentaires sur le Défunt :")
    y_body -= 0.5 * cm
    
    data = [
        ["Nationalité", metadata.get('nationalite_defunt', '{nationalite}')],
        ["Profession", metadata.get('profession_defunt', '{profession}')],
        ["Adresse habituelle", metadata.get('adresse_defunt', '{adresse}')],
        ["Déclarant", f"{metadata.get('nom_declarant', '{declarant}')} ({metadata.get('lien_declarant', '{lien}')})"],
        ["CNI Déclarant", metadata.get('cni_declarant', '{cni}')]
    ]
    
    table = Table(data, colWidths=[5 * cm, 12 * cm])
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), HexColor('#F5F5F5')),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#DDDDDD'))
    ]))
    
    table.wrapOn(p, width, height)
    table_height = table._height
    y_body -= table_height
    table.drawOn(p, 2 * cm, y_body)
    
    # ---------------- CONCLUSION ----------------
    y_body -= 1.5 * cm
    texte_concl = "Le présent certificat est délivré à l'intéressé(e) ou à ses ayants droit pour servir et valoir ce que de droit."
    para_concl = Paragraph(texte_concl, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)
    y_body -= para_concl.height + 0.8 * cm
    
    # ---------------- 5 ZONES DE VALIDATION ----------------
    zone_y = min(1.5 * cm, y_body - 4.5 * cm) 
    
    from datetime import datetime
    date_str = dossier.updated_at.strftime("%d/%m/%Y") if dossier.updated_at else datetime.now().strftime("%d/%m/%Y")
    
    # ZONE 1 : QR Code + Textes
    z1_x = 1.0 * cm
    qr_size = 2.5 * cm
    qr_y = zone_y + 0.8 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, z1_x + 0.5*cm, qr_y, width=qr_size, height=qr_size)
    p.setFont("Helvetica", 6)
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.2 * cm, "Scannez pour vérifier")
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.5 * cm, "l'authenticité")
    p.drawCentredString(z1_x + 1.7*cm, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    # ZONE 2 : Timbre Fiscal
    z2_x = z1_x + 3.5 * cm
    if timbre_ref:
        _draw_secure_timbre(p, z2_x, zone_y + 0.8 * cm, timbre_ref)

    # ZONE 3 : Tampon rond (Cachet Communal)
    z3_x = z2_x + 3.5 * cm
    cachet_y = zone_y + 0.2 * cm
    if cachet_path and os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), z3_x, cachet_y, width=4.0*cm, height=4.0*cm, mask='auto')

    # ZONE 4 : Texte Officier
    z4_x = z3_x + 4.2 * cm
    text_y = zone_y + 3.5 * cm
    p.setFont("Helvetica", 9)
    p.drawCentredString(z4_x + 1.5*cm, text_y, f"Fait à {commune_name.capitalize()},")
    p.drawCentredString(z4_x + 1.5*cm, text_y - 0.4*cm, f"le {date_str}")
    p.setFont("Helvetica-Bold", 9)
    p.drawCentredString(z4_x + 1.5*cm, text_y - 1.2*cm, officier_name)
    p.setFont("Helvetica", 9)
    p.drawCentredString(z4_x + 1.5*cm, text_y - 1.6*cm, "Officier de l'Etat Civil")

    # ZONE 5 : Tampon Ovale (Nominal) + Signature manuscrite
    z5_x = z4_x + 3.0 * cm
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
    timbre_ref = "TF-110A-D980"
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
    _draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref,
                              cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    p.showPage()
    p.save()
    with open('certificat_deces_keur_massar.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_deces_keur_massar.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_deces_keur_massar.png')
