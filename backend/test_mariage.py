import os
from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT

def _draw_mariage_pdf_content(p, width, height):
    NOIR = HexColor('#000000')

    # Styles
    style_normal = ParagraphStyle(name='Normal', fontName='Helvetica', fontSize=12, leading=16)
    style_bold = ParagraphStyle(name='Bold', fontName='Helvetica-Bold', fontSize=12, leading=16)

    # --- 1. EN-TETES ---
    p.setFillColor(NOIR)
    
    # En-tête gauche
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2 * cm, height - 2 * cm, "REGION DE DAKAR")
    p.drawString(2 * cm, height - 2.5 * cm, "VILLE DE DAKAR")
    p.drawString(2 * cm, height - 3 * cm, "COMMUNE D'ARRONDISSEMENT")
    p.drawString(2 * cm, height - 3.5 * cm, "DE FANN - POINT E - AMITIE")
    p.drawString(2 * cm, height - 4 * cm, "CENTRE SECONDAIRE")
    p.drawString(2 * cm, height - 4.5 * cm, "EX-GRAND DAKAR")
    
    # En-tête droit
    p.setFont("Helvetica-Bold", 10)
    p.drawString(14 * cm, height - 2 * cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica", 10)
    p.drawString(14 * cm, height - 2.5 * cm, "Un Peuple - Un But - Une Foi")

    # --- 2. INFORMATIONS REGISTRE ---
    y_reg = height - 6.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2 * cm, y_reg, "Registre N° 179")
    
    p.setFont("Helvetica", 11)
    p.drawString(2 * cm, y_reg - 0.7 * cm, "L'an deux mille vingt-quatre,")
    p.drawString(2 * cm, y_reg - 1.4 * cm, "Du mois d'Octobre, à dix-sept heures trente minutes.")

    # --- 3. TITRE ---
    y_titre = height - 9.5 * cm
    p.setFont("Helvetica-Bold", 16)
    p.drawCentredString(width / 2, y_titre, "CERTIFICAT DE MARIAGE CONSTATÉ")

    # --- 4. CORPS DU TEXTE ---
    y_body = y_titre - 1.5 * cm
    
    p.setFont("Helvetica", 11)
    para_intro = Paragraph(
        "Nous, <b>Oumou Sy</b>, Officier d'État civil du <b>CENTRE SECONDAIRE DE FANN</b>, certifions à tous ceux "
        "qu'il appartiendra que :", style_normal)
    para_intro.wrap(width - 4 * cm, 5 * cm)
    para_intro.drawOn(p, 2 * cm, y_body - para_intro.height)
    
    y_body -= para_intro.height + 0.8 * cm

    # Mari
    mari_text = (
        "<b>Monsieur Barka KOITA,</b><br/>"
        "Profession : <b>Commerçant</b>, domicilié à <b>Point-E</b>,<br/>"
        "Né le 11 Novembre 1979 à Dakar,<br/>"
        "Fils de <b>Harouna KOITA</b> et de <b>Coumba SOW</b>,<br/>"
        "D'une part,"
    )
    para_mari = Paragraph(mari_text, style_normal)
    para_mari.wrap(width - 4 * cm, 5 * cm)
    para_mari.drawOn(p, 2 * cm, y_body - para_mari.height)
    
    y_body -= para_mari.height + 0.5 * cm
    
    # Et
    p.drawString(2 * cm, y_body, "Et")
    y_body -= 0.8 * cm

    # Epouse
    epouse_text = (
        "<b>Mademoiselle Fatou SECK,</b><br/>"
        "Profession : <b>Ménagère</b>, domiciliée à <b>Point-E</b>,<br/>"
        "Née le <b>20 Février 1999</b> à Lambaye,<br/>"
        "Fille de <b>Ngora SECK</b> et de <b>Soukeye NDIAYE</b>,<br/>"
        "D'autre part,"
    )
    para_epouse = Paragraph(epouse_text, style_normal)
    para_epouse.wrap(width - 4 * cm, 5 * cm)
    para_epouse.drawOn(p, 2 * cm, y_body - para_epouse.height)
    
    y_body -= para_epouse.height + 0.8 * cm

    # Conclusion
    concl_text = (
        "Ont contracté mariage entre eux selon la coutume, <b>le 31 Octobre 2024</b>,<br/>"
        "Option souscrite : <b>Monogamie</b>,<br/>"
        "Et que ce mariage a été enregistré par nous sur leur demande le 31 Octobre 2024 à Dakar,<br/>"
        "Régime matrimonial choisi : <b>séparation des biens</b>."
    )
    para_concl = Paragraph(concl_text, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)
    
    y_body -= para_concl.height + 1.2 * cm

    # Footer
    p.setFont("Helvetica", 11)
    p.drawString(2 * cm, y_body, "En foi de quoi, nous avons délivré le présent certificat pour servir et valoir ce que de droit.")
    
    # Signatures
    y_sig = y_body - 1 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawString(12 * cm, y_sig, "L'Officier de l'Etat Civil")
    p.setFont("Helvetica", 11)
    p.drawString(12 * cm, y_sig - 0.6 * cm, "Fait à Dakar, le 31 Octobre 2024")

def generate():
    buffer = BytesIO()
    pagesize = A4 # Portrait
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize
    _draw_mariage_pdf_content(p, width, height)
    p.showPage()
    p.save()
    with open('certificat_mariage_fictif.pdf', 'wb') as f:
        f.write(buffer.getvalue())

generate()

import fitz
doc = fitz.open('certificat_mariage_fictif.pdf')
page = doc.load_page(0)
pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_mariage_fictif.png')
