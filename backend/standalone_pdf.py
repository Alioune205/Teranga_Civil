from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor

def _draw_secure_timbre(p, x, y, timbre_ref):
    p.setFillColor(HexColor('#EEEEEE'))
    p.rect(x, y, 4*cm, 2.5*cm, fill=1)
    p.setFillColor(HexColor('#000000'))
    p.setFont("Helvetica-Bold", 8)
    p.drawString(x + 0.2*cm, y + 2*cm, "TIMBRE FISCAL")
    p.drawString(x + 0.2*cm, y + 0.5*cm, "Ref: " + (timbre_ref or ''))

def _draw_residence_pdf_content(p, width, height):
    VERT = HexColor('#00853F')
    NOIR = HexColor('#000000')
    BLEU_FONCE = HexColor('#0A1B2A')
    ROUGE = HexColor('#E31B23')

    # Top Left (Header)
    y = height - 2.5 * cm
    p.setFillColor(NOIR)
    p.setFont("Helvetica", 10)
    p.drawString(2 * cm, y, "Un Peuple - Un But - Une Foi")
    
    y -= 0.6 * cm
    p.setFont("Helvetica-Bold", 14)
    p.setFillColor(BLEU_FONCE)
    p.drawString(2 * cm, y, "REGION DE DAKAR")
    
    y -= 0.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2 * cm, y, "COMMUNE D'ARRONDISSEMENT DES")
    y -= 0.5 * cm
    p.drawString(2 * cm, y, "PARCELLES ASSAINIES")

    # Top Right (Title)
    p.setFont("Helvetica-Bold", 24)
    p.setFillColor(BLEU_FONCE)
    p.drawString(10 * cm, height - 3.5 * cm, "CERTIFICAT DE RESIDENCE")
    
    p.setStrokeColor(NOIR)
    p.setLineWidth(1)
    p.line(10.5 * cm, height - 3.8 * cm, 18.5 * cm, height - 3.8 * cm)

    # Reference
    y_ref = height - 5 * cm
    p.setFont("Helvetica", 10)
    p.setFillColor(NOIR)
    p.drawString(11 * cm, y_ref, "N° Pièce portée : RES-2026-0001")

    # Body text
    y_body = height - 8 * cm
    p.setFont("Helvetica", 12)
    p.drawString(2 * cm, y_body, "Nous soussigné(e) Maire de la Commune de Parcelles assainies certifions")

    y_body -= 1.2 * cm
    p.drawString(2 * cm, y_body, "que Mamadou Diop")
    p.setFont("Helvetica-Oblique", 10)
    p.setFillColor(HexColor('#0055A4'))
    p.drawString(7 * cm, y_body, "(NOM ET PRÉNOMS)")
    p.setFillColor(NOIR)
    p.setFont("Helvetica", 12)
    p.drawString(11 * cm, y_body, "né(e) le 12 Mai 1985")

    y_body -= 1.2 * cm
    p.drawString(2 * cm, y_body, "à Dakar")
    p.setFont("Helvetica-Oblique", 10)
    p.setFillColor(HexColor('#0055A4'))
    p.drawString(5 * cm, y_body, "(LIEU DE NAISSANCE)")
    p.setFillColor(NOIR)
    p.setFont("Helvetica", 12)
    p.drawString(9 * cm, y_body, "et qu'il (elle) réside à Villa 123, Unité 15")

    y_body -= 1.2 * cm
    p.drawString(2 * cm, y_body, "au quartier Unité 15")
    p.setFont("Helvetica-Oblique", 10)
    p.setFillColor(HexColor('#0055A4'))
    p.drawString(6 * cm, y_body, "(NOM DU QUARTIER)")
    p.setFillColor(NOIR)
    p.setFont("Helvetica", 12)
    p.drawString(10 * cm, y_body, "depuis 01 Janvier 2010")

    # Note validité
    y_body -= 2 * cm
    p.setFont("Helvetica-BoldOblique", 11)
    p.setFillColor(ROUGE)
    p.drawCentredString(width / 2, y_body, "Validité : 3 mois à compter de la date de délivrance")

    # Bottom Signatures
    y_sig = height - 16 * cm
    p.setFont("Helvetica", 11)
    p.setFillColor(NOIR)
    p.drawString(11 * cm, y_sig, "Fait à Parcelles assainies, le 12/06/2026")

    y_sig -= 1 * cm
    p.setFont("Helvetica-Oblique", 10)
    p.drawString(12 * cm, y_sig, "P. le Maire et P.O")
    y_sig -= 0.5 * cm
    p.drawString(12 * cm, y_sig, "l'Officier de l'Etat Civil")

    # Timbre
    _draw_secure_timbre(p, 2 * cm, y_sig - 4 * cm, "TIM-999-XYZ")

def generate():
    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    _draw_residence_pdf_content(p, width, height)
    p.showPage()
    p.save()
    with open('certificat_residence_fictif.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()
