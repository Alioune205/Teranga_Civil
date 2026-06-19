import os
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader

def _draw_residence_pdf_content(p, width, height, commune_name="KEUR MASSAR"):
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
    p.drawString(15 * cm, y_ref, "N° Pièce portée : RES-2026-0001")

    # Corps du texte (texte continu)
    y_body = height - 7.5 * cm
    p.setFont("Helvetica", 14)
    p.drawString(2 * cm, y_body, f"Nous soussigné(e) Maire de la Commune de {commune_name.capitalize()} certifions")

    y_body -= 1 * cm
    line2 = "que Mamadou Diop né(e) le 12 Mai 1985 à Dakar et qu'il (elle) réside à Villa 123, Unité 15"
    p.drawString(2 * cm, y_body, line2)

    y_body -= 1 * cm
    line3 = "au quartier Unité 15 depuis 01 Janvier 2010."
    p.drawString(2 * cm, y_body, line3)

    # Cadre ETAT CIVIL (en bas à gauche)
    box_y = 4 * cm
    p.setDash([3, 3], 0)
    p.setLineWidth(1.5)
    p.setStrokeColor(NOIR)
    p.roundRect(2*cm, box_y, 8*cm, 4.5*cm, 5, fill=0)
    p.setDash([], 0)
    
    p.setFont("Helvetica-Bold", 8)
    p.drawCentredString(6*cm, box_y + 3.8*cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica-Bold", 7)
    p.drawCentredString(6*cm, box_y + 3.4*cm, "COMMUNE DE")
    p.drawCentredString(6*cm, box_y + 3.1*cm, commune_name.upper())
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(6*cm, box_y + 2.4*cm, "ETAT CIVIL")
    p.setFont("Helvetica-Bold", 10)
    p.drawString(3*cm, box_y + 1*cm, "S/D")
    p.setDash([1, 2], 0)
    p.setLineWidth(1)
    p.line(4*cm, box_y + 1*cm, 6*cm, box_y + 1*cm)
    p.setDash([], 0)
    p.drawString(6.5*cm, box_y + 1*cm, "N°")
    p.setDash([1, 2], 0)
    p.line(7*cm, box_y + 1*cm, 9*cm, box_y + 1*cm)
    p.setDash([], 0)

    # Signature (en bas à droite)
    y_sig = 7 * cm
    p.setFont("Helvetica", 14)
    p.setFillColor(NOIR)
    p.drawString(16 * cm, y_sig, f"Fait à {commune_name.capitalize()}, le 12/06/2026")

    y_sig -= 1 * cm
    p.setFont("Helvetica", 14)
    p.drawCentredString(21 * cm, y_sig, "P. le Maire et P.O")
    y_sig -= 0.6 * cm
    p.drawCentredString(21 * cm, y_sig, "l'Officier de l'Etat Civil")

    # Images
    cachet_path = r"C:\Users\senep\Desktop\Hackathon\Cachet Etat civil keur Massar.jpg"
    cachet_nominal_path = r"C:\Users\senep\Desktop\Hackathon\Cachet nominale Keur Massar.jpg"
    signature_path = r"C:\Users\senep\Desktop\Hackathon\signature keur massar.jpg"
    timbre_path = r"C:\Users\senep\Desktop\Hackathon\Timbre.png"

    if os.path.exists(cachet_nominal_path):
        p.drawImage(ImageReader(cachet_nominal_path), 17 * cm, y_sig - 2.5 * cm, width=4*cm, height=2*cm, mask='auto')

    if os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), 22.5 * cm, y_sig - 4 * cm, width=4.5*cm, height=4.5*cm, mask='auto')
    
    if os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), 19 * cm, y_sig - 2.5 * cm, width=4.5*cm, height=2.5*cm, mask='auto')

    if os.path.exists(timbre_path):
        p.drawImage(ImageReader(timbre_path), 11 * cm, 4.5 * cm, width=3.5*cm, height=4*cm, mask='auto')

def generate():
    buffer = BytesIO()
    pagesize = landscape(A4)
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    _draw_residence_pdf_content(p, width, height)
    p.showPage()
    p.save()
    with open('certificat_residence_keur_massar.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_residence_keur_massar.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_keur_massar.png')
