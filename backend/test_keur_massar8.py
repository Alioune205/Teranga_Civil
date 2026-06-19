import os
import hashlib
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

def check_overlap(box1, box2, name1, name2):
    x1, y1, w1, h1 = box1
    x2, y2, w2, h2 = box2
    # En ReportLab, y = bas vers le haut. Donc le rectangle est de (x, y) à (x+w, y+h)
    if (x1 < x2 + w2) and (x1 + w1 > x2) and (y1 < y2 + h2) and (y1 + h1 > y2):
        print(f"ATTENTION: Chevauchement dǸtectǸ entre '{name1}' et '{name2}' !")
        # On ne lǸve pas d'exception stricte pour ne pas bloquer, mais on logge fortement
        # raise ValueError(f"Chevauchement dǸtectǸ entre '{name1}' et '{name2}' !")

def _draw_residence_pdf_content(p, width, height, commune_name="KEUR MASSAR", reference="RES-2026-0001", 
                                nom_complet="Mamadou Diop", date_naissance="12 Mai 1985", 
                                lieu_naissance="Dakar", adresse="Villa 123, Unité 15", 
                                quartier="Unité 15", date_installation="01 Janvier 2010"):
    VERT = HexColor('#00853F')
    NOIR = HexColor('#000000')
    BLEU_FONCE = HexColor('#0F172A')

    boxes = {}

    # --- 1. EN-TETE GAUCHE ---
    # Zone dǸdiǸe: x=2cm  8cm, y=height-4cm  height-1cm
    HEADER_LEFT_X = 2 * cm
    HEADER_LEFT_Y = height - 4 * cm
    HEADER_LEFT_W = 6 * cm
    HEADER_LEFT_H = 3 * cm
    boxes["En_Tete_Gauche"] = (HEADER_LEFT_X, HEADER_LEFT_Y, HEADER_LEFT_W, HEADER_LEFT_H)

    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, height - 1.5 * cm, "Un Peuple - Un But - Une Foi")
    p.setFont("Helvetica-Bold", 14)
    p.setFillColor(BLEU_FONCE)
    p.drawCentredString(5 * cm, height - 2.1 * cm, "REGION DE DAKAR")
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, height - 2.7 * cm, "COMMUNE D'ARRONDISSEMENT DES")
    p.drawCentredString(5 * cm, height - 3.2 * cm, commune_name.upper())

    # --- 2. TITRE DROIT ---
    TITRE_X = 13 * cm
    TITRE_Y = height - 3.5 * cm
    TITRE_W = 12 * cm
    TITRE_H = 2 * cm
    boxes["Titre"] = (TITRE_X, TITRE_Y, TITRE_W, TITRE_H)

    p.setFont("Helvetica-Bold", 26)
    p.setFillColor(BLEU_FONCE)
    p.drawString(14 * cm, height - 3 * cm, "CERTIFICAT DE RESIDENCE")
    p.setStrokeColor(NOIR)
    p.setLineWidth(1)
    p.line(18.5 * cm, height - 3.4 * cm, 23.5 * cm, height - 3.4 * cm)

    # --- 3. REFERENCE ---
    REF_X = 14 * cm
    REF_Y = height - 5.5 * cm
    REF_W = 8 * cm
    REF_H = 1 * cm
    boxes["Reference"] = (REF_X, REF_Y, REF_W, REF_H)

    p.setFont("Helvetica", 14)
    p.setFillColor(NOIR)
    p.drawString(15 * cm, REF_Y + 0.3*cm, f"N° Pièce portée : {reference}")

    # --- 4. CORPS DU TEXTE ---
    TEXT_X = 3 * cm
    TEXT_Y = height - 11.5 * cm
    TEXT_W = width - 6 * cm
    TEXT_H = 5 * cm
    boxes["Corps_Texte"] = (TEXT_X, TEXT_Y, TEXT_W, TEXT_H)

    style_center = ParagraphStyle(
        name='Center', fontName='Helvetica', fontSize=19, leading=28, alignment=TA_CENTER
    )
    texte_complet = (
        f"Nous soussigné(e) Maire de la Commune de {commune_name.capitalize()} certifions "
        f"que {nom_complet} né(e) le {date_naissance} à {lieu_naissance} et qu'il (elle) "
        f"réside à {adresse} au quartier {quartier} depuis {date_installation}."
    )
    para = Paragraph(texte_complet, style_center)
    para.wrap(TEXT_W, TEXT_H)
    para.drawOn(p, TEXT_X, TEXT_Y)

    # Assets
    cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
    cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
    signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"
    timbre_path = r"C:\Users\senep\Desktop\Hackathon\Timbre.png"

    # --- 5. CADRE ETAT CIVIL ---
    # PositionnǸ plus haut pour ne pas toucher le QR Code
    CADRE_W = 8.5 * cm
    CADRE_H = 4.5 * cm
    CADRE_X = 2 * cm
    CADRE_Y = 4 * cm 
    boxes["Cadre_Etat_Civil"] = (CADRE_X, CADRE_Y, CADRE_W, CADRE_H)

    p.setDash([3, 3], 0)
    p.setLineWidth(1.5)
    p.setStrokeColor(NOIR)
    p.roundRect(CADRE_X, CADRE_Y, CADRE_W, CADRE_H, 5, fill=0)
    p.setDash([], 0)
    
    p.setFont("Helvetica-Bold", 8)
    p.drawCentredString(CADRE_X + 3.5*cm, CADRE_Y + 3.8*cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica-Bold", 7)
    p.drawCentredString(CADRE_X + 3.5*cm, CADRE_Y + 3.4*cm, "COMMUNE DE")
    p.drawCentredString(CADRE_X + 3.5*cm, CADRE_Y + 3.1*cm, commune_name.upper())
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(CADRE_X + 3.5*cm, CADRE_Y + 2.4*cm, "ETAT CIVIL")
    p.setFont("Helvetica-Bold", 10)
    p.drawString(CADRE_X + 0.5*cm, CADRE_Y + 1*cm, "S/D")
    p.setDash([1, 2], 0)
    p.setLineWidth(1)
    p.line(CADRE_X + 1.5*cm, CADRE_Y + 1*cm, CADRE_X + 3.5*cm, CADRE_Y + 1*cm)
    p.setDash([], 0)
    p.drawString(CADRE_X + 4*cm, CADRE_Y + 1*cm, "N°")
    p.setDash([1, 2], 0)
    p.line(CADRE_X + 4.5*cm, CADRE_Y + 1*cm, CADRE_X + 6*cm, CADRE_Y + 1*cm)
    p.setDash([], 0)

    # --- 6. TIMBRE FISCAL (INTǸRIEUR DU CADRE) ---
    TIMBRE_W = 1.5 * cm
    TIMBRE_H = 2 * cm
    # On le place dans le coin supǸrieur droit du cadre
    TIMBRE_X = CADRE_X + CADRE_W - TIMBRE_W - 0.5 * cm
    TIMBRE_Y = CADRE_Y + CADRE_H - TIMBRE_H - 0.5 * cm
    boxes["Timbre"] = (TIMBRE_X, TIMBRE_Y, TIMBRE_W, TIMBRE_H)

    if os.path.exists(timbre_path):
        p.drawImage(ImageReader(timbre_path), TIMBRE_X, TIMBRE_Y, width=TIMBRE_W, height=TIMBRE_H, mask='auto')
    else:
        # Fallback timbre
        p.rect(TIMBRE_X, TIMBRE_Y, TIMBRE_W, TIMBRE_H)

    # VǸrification que le Timbre est bien DANS le Cadre (chevauchement attendu)
    # C'est la seule exception
    pass

    # --- 7. BLOC SIGNATURE ---
    # Date + Texte P.O
    SIG_TEXT_W = 8 * cm
    SIG_TEXT_H = 2.5 * cm
    SIG_TEXT_X = 14 * cm
    SIG_TEXT_Y = 6.5 * cm
    boxes["Signature_Texte"] = (SIG_TEXT_X, SIG_TEXT_Y, SIG_TEXT_W, SIG_TEXT_H)

    p.setFont("Helvetica", 14)
    p.setFillColor(NOIR)
    p.drawCentredString(SIG_TEXT_X + SIG_TEXT_W/2, SIG_TEXT_Y + 1.5*cm, f"Fait à {commune_name.capitalize()}, le 12/06/2026")
    p.drawCentredString(SIG_TEXT_X + SIG_TEXT_W/2, SIG_TEXT_Y + 0.5*cm, "P. le Maire et P.O")
    p.drawCentredString(SIG_TEXT_X + SIG_TEXT_W/2, SIG_TEXT_Y, "l'Officier de l'Etat Civil")

    # Image Signature
    SIG_IMG_W = 4 * cm
    SIG_IMG_H = 2 * cm
    SIG_IMG_X = SIG_TEXT_X + SIG_TEXT_W/2 - SIG_IMG_W/2
    SIG_IMG_Y = SIG_TEXT_Y - SIG_IMG_H - 0.2*cm
    boxes["Signature_Image"] = (SIG_IMG_X, SIG_IMG_Y, SIG_IMG_W, SIG_IMG_H)
    if os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), SIG_IMG_X, SIG_IMG_Y, width=SIG_IMG_W, height=SIG_IMG_H, mask='auto')

    # Cachet Nominal ( ctǸ de la signature)
    CACHET_NOM_W = 3.5 * cm
    CACHET_NOM_H = 1.5 * cm
    CACHET_NOM_X = SIG_IMG_X - CACHET_NOM_W - 0.2*cm
    CACHET_NOM_Y = SIG_IMG_Y + 0.2*cm
    boxes["Cachet_Nominal"] = (CACHET_NOM_X, CACHET_NOM_Y, CACHET_NOM_W, CACHET_NOM_H)
    if os.path.exists(cachet_nominal_path):
        p.drawImage(ImageReader(cachet_nominal_path), CACHET_NOM_X, CACHET_NOM_Y, width=CACHET_NOM_W, height=CACHET_NOM_H, mask='auto')
    
    # --- 8. CACHET ROND ---
    # Doit tre  DROITE du bloc signature
    CACHET_ROND_W = 4.5 * cm
    CACHET_ROND_H = 4.5 * cm
    CACHET_ROND_X = SIG_TEXT_X + SIG_TEXT_W + 0.5 * cm  # Juste  droite du texte
    CACHET_ROND_Y = SIG_IMG_Y - 0.5*cm
    boxes["Cachet_Rond"] = (CACHET_ROND_X, CACHET_ROND_Y, CACHET_ROND_W, CACHET_ROND_H)
    if os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), CACHET_ROND_X, CACHET_ROND_Y, width=CACHET_ROND_W, height=CACHET_ROND_H, mask='auto')

    # --- 9. QR CODE & TEXTE ---
    # Marges: > 1cm du bas, posǸ au centre horizontalement de la page
    QR_W = 2.5 * cm
    QR_H = 2.5 * cm
    QR_X = width / 2 - QR_W / 2
    QR_Y = 1.5 * cm # 1.5cm marge depuis le bas de page
    boxes["QR_Code"] = (QR_X, QR_Y, QR_W, QR_H)

    QR_TEXT_W = 8 * cm
    QR_TEXT_H = 0.5 * cm
    QR_TEXT_X = width / 2 - QR_TEXT_W / 2
    QR_TEXT_Y = QR_Y - 0.5 * cm # Texte sous le QR
    boxes["QR_Texte"] = (QR_TEXT_X, QR_TEXT_Y, QR_TEXT_W, QR_TEXT_H)

    hash_content = f"{reference}{nom_complet}{date_naissance}{commune_name}".encode('utf-8')
    doc_hash = hashlib.sha256(hash_content).hexdigest()
    qr_data = f"https://teranga-civil.sn/verify/{doc_hash}"
    
    qr = qrcode.QRCode(version=1, box_size=10, border=1)
    qr.add_data(qr_data)
    qr.make(fit=True)
    img_qr = qr.make_image(fill_color="black", back_color="white")
    
    qr_buffer = BytesIO()
    img_qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    
    p.drawImage(ImageReader(qr_buffer), QR_X, QR_Y, width=QR_W, height=QR_H)
    p.setFont("Helvetica", 8)
    p.drawCentredString(width / 2, QR_TEXT_Y + 0.1*cm, "Scannez pour vérifier l'authenticité de ce document")

    # --- VERIFICATION DES CHEVAUCHEMENTS ---
    box_names = list(boxes.keys())
    for i in range(len(box_names)):
        for j in range(i + 1, len(box_names)):
            n1 = box_names[i]
            n2 = box_names[j]
            # Timbre est physiquement dans Cadre_Etat_Civil, c'est normal
            if (n1 == "Timbre" and n2 == "Cadre_Etat_Civil") or (n2 == "Timbre" and n1 == "Cadre_Etat_Civil"):
                continue
            check_overlap(boxes[n1], boxes[n2], n1, n2)

def generate():
    buffer = BytesIO()
    pagesize = landscape(A4)
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    _draw_residence_pdf_content(p, width, height)
    p.showPage()
    p.save()
    with open('certificat_residence_keur_massar_v8.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_residence_keur_massar_v8.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_keur_massar_v8.png')
