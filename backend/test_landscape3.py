from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor

def _draw_secure_timbre(p, x, y, timbre_ref):
    p.setFillColor(HexColor('#EEEEEE'))
    p.rect(x, y, 4*cm, 2.5*cm, fill=1)
    p.setFillColor(HexColor('#000000'))
    p.setFont("Helvetica-Bold", 8)
    p.drawString(x + 0.2*cm, y + 2*cm, "TIMBRE FISCAL")
    p.drawString(x + 0.2*cm, y + 0.5*cm, "Ref: " + (timbre_ref or ''))

def _draw_field(p, x, y, width, value, label):
    p.setFont("Helvetica-Bold", 12)
    p.setFillColor(HexColor('#000000'))
    p.drawCentredString(x + width/2, y + 2, value)
    p.setDash([1, 2], 0)
    p.setLineWidth(1)
    p.setStrokeColor(HexColor('#000000'))
    p.line(x, y, x + width, y)
    p.setDash([], 0)
    p.setFont("Helvetica-Oblique", 9)
    p.setFillColor(HexColor('#1D4ED8'))
    p.drawCentredString(x + width/2, y - 10, f"({label})")

def _draw_residence_pdf_content(p, width, height):
    VERT = HexColor('#00853F')
    NOIR = HexColor('#000000')
    BLEU_FONCE = HexColor('#0F172A')
    BLEU_CLAIR = HexColor('#1D4ED8')
    ROUGE = HexColor('#E31B23')

    # En-tête gauche
    y = height - 2 * cm
    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, y, "Un Peuple - Un But - Une Foi")
    y -= 0.6 * cm
    p.setFont("Helvetica-Bold", 14)
    p.setFillColor(BLEU_FONCE)
    p.drawCentredString(5 * cm, y, f"REGION DE DAKAR")
    y -= 0.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, y, "COMMUNE D'ARRONDISSEMENT DES")
    y -= 0.5 * cm
    p.drawCentredString(5 * cm, y, "PARCELLES ASSAINIES")

    # Titre droit
    p.setFont("Helvetica-Bold", 26)
    p.setFillColor(BLEU_FONCE)
    p.drawString(14 * cm, height - 3 * cm, "CERTIFICAT DE RESIDENCE")
    p.setStrokeColor(NOIR)
    p.setLineWidth(1)
    p.line(18.5 * cm, height - 3.4 * cm, 23.5 * cm, height - 3.4 * cm)

    # Référence
    y_ref = height - 5 * cm
    p.setFont("Helvetica", 11)
    p.setFillColor(NOIR)
    p.drawString(15 * cm, y_ref, "N° Pièce portée : ")
    p.setDash([1, 2], 0)
    p.line(18 * cm, y_ref, 23 * cm, y_ref)
    p.setDash([], 0)
    p.setFont("Helvetica-Bold", 11)
    p.drawString(18.5 * cm, y_ref + 2, "RES-2026-0001")

    # Corps du texte
    y_body = height - 7.5 * cm
    p.setFont("Helvetica", 14)
    p.drawString(2 * cm, y_body, f"Nous soussigné(e) Maire de la Commune de Parcelles assainies certifions")

    y_body -= 1.8 * cm
    p.setFont("Helvetica", 13)
    p.drawString(2 * cm, y_body, "que")
    _draw_field(p, 3 * cm, y_body, 12 * cm, "Mamadou Diop", "NOM ET PRÉNOMS")
    p.setFont("Helvetica", 13)
    p.setFillColor(NOIR)
    p.drawString(15.2 * cm, y_body, "né(e) le")
    _draw_field(p, 17 * cm, y_body, 9 * cm, "12 Mai 1985", "DATE DE NAISSANCE")
    p.setFont("Helvetica", 13)
    p.setFillColor(NOIR)
    p.drawString(26.2 * cm, y_body, ",")

    y_body -= 1.8 * cm
    p.drawString(2 * cm, y_body, "à")
    _draw_field(p, 2.5 * cm, y_body, 10 * cm, "Dakar", "LIEU DE NAISSANCE")
    p.setFont("Helvetica", 13)
    p.setFillColor(NOIR)
    p.drawString(12.8 * cm, y_body, "et qu'il (elle) réside à")
    _draw_field(p, 17 * cm, y_body, 10 * cm, "Villa 123, Unité 15", "ADRESSE COMPLÈTE")

    y_body -= 1.8 * cm
    p.drawString(2 * cm, y_body, "au quartier")
    _draw_field(p, 4.8 * cm, y_body, 9.7 * cm, "Unité 15", "NOM DU QUARTIER")
    p.setFont("Helvetica", 13)
    p.setFillColor(NOIR)
    p.drawString(14.8 * cm, y_body, "depuis")
    _draw_field(p, 16.5 * cm, y_body, 10.5 * cm, "01 Janvier 2010", "DATE D'INSTALLATION")

    # Cadre ETAT CIVIL (en bas à gauche)
    box_y = 2.5 * cm
    p.setDash([3, 3], 0)
    p.setLineWidth(1.5)
    p.setStrokeColor(NOIR)
    p.roundRect(2*cm, box_y, 8*cm, 4.5*cm, 5, fill=0)
    p.setDash([], 0)
    
    p.setFont("Helvetica-Bold", 8)
    p.drawCentredString(6*cm, box_y + 3.8*cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica-Bold", 7)
    p.drawCentredString(6*cm, box_y + 3.4*cm, "COMMUNE DES")
    p.drawCentredString(6*cm, box_y + 3.1*cm, "PARCELLES ASSAINIES")
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
    y_sig = 5.5 * cm
    p.setFont("Helvetica", 12)
    p.setFillColor(NOIR)
    p.drawString(16 * cm, y_sig, f"Fait à Parcelles assainies, le")
    p.setDash([1, 2], 0)
    p.line(21 * cm, y_sig, 26 * cm, y_sig)
    p.setDash([], 0)
    p.setFont("Helvetica-Bold", 12)
    p.drawCentredString(23.5 * cm, y_sig + 2, "12/06/2026")

    y_sig -= 1 * cm
    p.setFont("Helvetica-Oblique", 11)
    p.drawCentredString(21 * cm, y_sig, "P. le Maire et P.O")
    y_sig -= 0.6 * cm
    p.drawCentredString(21 * cm, y_sig, "l'Officier de l'Etat Civil")

    # Timbre
    _draw_secure_timbre(p, 11 * cm, 3 * cm, "TIM-999-XYZ")

def generate():
    buffer = BytesIO()
    pagesize = landscape(A4)
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    _draw_residence_pdf_content(p, width, height)
    p.showPage()
    p.save()
    with open('certificat_residence_fictif_landscape.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_residence_fictif_landscape.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_fictif_paysage_v2.png')
