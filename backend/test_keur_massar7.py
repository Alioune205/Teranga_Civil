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

def _draw_residence_pdf_content(p, width, height, commune_name="KEUR MASSAR", reference="RES-2026-0001", 
                                nom_complet="Mamadou Diop", date_naissance="12 Mai 1985", 
                                lieu_naissance="Dakar", adresse="Villa 123, Unité 15", 
                                quartier="Unité 15", date_installation="01 Janvier 2010"):
    VERT = HexColor('#00853F')
    NOIR = HexColor('#000000')
    BLEU_FONCE = HexColor('#0F172A')

    # En-tête gauche
    y = height - 2 * cm
    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, y, "Un Peuple - Un But - Une Foi")
    y -= 0.6 * cm
    p.setFont("Helvetica-Bold", 14)
    p.setFillColor(BLEU_FONCE)
    p.drawCentredString(5 * cm, y, "REGION DE DAKAR")
    y -= 0.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, y, "COMMUNE D'ARRONDISSEMENT DES")
    y -= 0.5 * cm
    p.drawCentredString(5 * cm, y, commune_name.upper())

    # Titre droit
    p.setFont("Helvetica-Bold", 26)
    p.setFillColor(BLEU_FONCE)
    p.drawString(14 * cm, height - 3 * cm, "CERTIFICAT DE RESIDENCE")
    p.setStrokeColor(NOIR)
    p.setLineWidth(1)
    p.line(18.5 * cm, height - 3.4 * cm, 23.5 * cm, height - 3.4 * cm)

    # Référence
    y_ref = height - 5 * cm
    p.setFont("Helvetica", 14)
    p.setFillColor(NOIR)
    p.drawString(15 * cm, y_ref, f"N° Pièce portée : {reference}")

    # Corps du texte centré (avec Paragraph)
    style_center = ParagraphStyle(
        name='Center',
        fontName='Helvetica',
        fontSize=19,
        leading=28,
        alignment=TA_CENTER
    )
    
    texte_complet = (
        f"Nous soussigné(e) Maire de la Commune de {commune_name.capitalize()} certifions "
        f"que {nom_complet} né(e) le {date_naissance} à {lieu_naissance} et qu'il (elle) "
        f"réside à {adresse} au quartier {quartier} depuis {date_installation}."
    )
    
    para = Paragraph(texte_complet, style_center)
    # Marges: x=3cm, width=width-6cm pour laisser la place au texte plus grand.
    para_width = width - 6 * cm
    para_height = 5 * cm
    para.wrap(para_width, para_height)
    para.drawOn(p, 3 * cm, height - 11.5 * cm)

    # Images assets
    cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
    cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
    signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"
    timbre_path = r"C:\Users\senep\Desktop\Hackathon\Timbre.png"

    # Cadre ETAT CIVIL (en bas à gauche)
    box_y = 3.5 * cm
    p.setDash([3, 3], 0)
    p.setLineWidth(1.5)
    p.setStrokeColor(NOIR)
    p.roundRect(2*cm, box_y, 8.5*cm, 4.5*cm, 5, fill=0)
    p.setDash([], 0)
    
    p.setFont("Helvetica-Bold", 8)
    p.drawCentredString(5.5*cm, box_y + 3.8*cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica-Bold", 7)
    p.drawCentredString(5.5*cm, box_y + 3.4*cm, "COMMUNE DE")
    p.drawCentredString(5.5*cm, box_y + 3.1*cm, commune_name.upper())
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(5.5*cm, box_y + 2.4*cm, "ETAT CIVIL")
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2.5*cm, box_y + 1*cm, "S/D")
    p.setDash([1, 2], 0)
    p.setLineWidth(1)
    p.line(3.5*cm, box_y + 1*cm, 5.5*cm, box_y + 1*cm)
    p.setDash([], 0)
    p.drawString(6*cm, box_y + 1*cm, "N°")
    p.setDash([1, 2], 0)
    p.line(6.5*cm, box_y + 1*cm, 8*cm, box_y + 1*cm)
    p.setDash([], 0)

    # Timbre à l'intérieur du cadre
    if os.path.exists(timbre_path):
        p.drawImage(ImageReader(timbre_path), 8*cm, box_y + 2.5*cm, width=1.5*cm, height=2*cm, mask='auto')

    # Signature bloc (en bas au centre/droite)
    y_sig = 7 * cm
    p.setFont("Helvetica", 14)
    p.setFillColor(NOIR)
    p.drawCentredString(19 * cm, y_sig, f"Fait à {commune_name.capitalize()}, le 12/06/2026")

    y_sig -= 1 * cm
    p.setFont("Helvetica", 14)
    p.drawCentredString(19 * cm, y_sig, "P. le Maire et P.O")
    y_sig -= 0.6 * cm
    p.drawCentredString(19 * cm, y_sig, "l'Officier de l'Etat Civil")

    # Signature and nominal cachet
    y_sig -= 2.5 * cm
    if os.path.exists(cachet_nominal_path):
        p.drawImage(ImageReader(cachet_nominal_path), 15 * cm, y_sig, width=3.5*cm, height=1.5*cm, mask='auto')
    if os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), 17.5 * cm, y_sig, width=4*cm, height=2*cm, mask='auto')
    
    # Cachet Rond (complètement à droite)
    if os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), 23 * cm, y_sig - 1*cm, width=4.5*cm, height=4.5*cm, mask='auto')

    # QR Code (Blockchain Placeholder)
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
    
    qr_y = 1.2 * cm
    qr_x = width / 2 - 1.25 * cm
    p.drawImage(ImageReader(qr_buffer), qr_x, qr_y + 0.4*cm, width=2.5*cm, height=2.5*cm)
    
    p.setFont("Helvetica", 8)
    p.drawCentredString(width / 2, qr_y, "Scannez pour vérifier l'authenticité de ce document")


def generate():
    buffer = BytesIO()
    pagesize = landscape(A4)
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    _draw_residence_pdf_content(p, width, height)
    p.showPage()
    p.save()
    with open('certificat_residence_keur_massar_v7.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_residence_keur_massar_v7.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_keur_massar_v7.png')
