import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

replacements = {
    "l'\ufffdtat Civil": "l'État Civil",
    "l'\ufffdTat Civil": "l'État Civil",
    "L'Officier de l'\ufffdtat": "L'Officier de l'État",
    "\ufffdLECTRONIQUE": "ÉLECTRONIQUE",
    "R\ufffdf": "Réf",
    "s\ufffdcuris\ufffd": "sécurisé",
    "d'\ufffdtre": "d'être",
    "dessin\ufffd": "dessiné",
    "tr\ufffds": "très",
    "Cr\ufffde": "Crée",
    "Cr\ufffder": "Créer",
    "N\ufffd": "N°",
    "Pi\ufffdce": "Pièce",
    "compl\ufffdte": "complète",
    "l'\ufffd": "l'É",
    " \ufffd": " É",
    "INT\ufffdRIEUR": "INTÉRIEUR",
    "Fait \ufffd": "Fait à",
}

for k, v in replacements.items():
    text = text.replace(k, v)

# Now, fix Cachet Nominal size
# We want to change cachet_nom_w and cachet_nom_h to 4.0 * cm
text = re.sub(r'cachet_nom_w\s*=\s*3\.5\s*\*\s*cm', 'cachet_nom_w = 4.0 * cm', text)
text = re.sub(r'cachet_nom_h\s*=\s*1\.5\s*\*\s*cm', 'cachet_nom_h = 4.0 * cm', text)
text = re.sub(r'CACHET_NOM_W\s*=\s*3\.5\s*\*\s*cm', 'CACHET_NOM_W = 4.0 * cm', text)
text = re.sub(r'CACHET_NOM_H\s*=\s*1\.5\s*\*\s*cm', 'CACHET_NOM_H = 4.0 * cm', text)

# Also fix the signature overlap that happens when seal is bigger.
# In _draw_mariage_pdf_content:
# cachet_nom_y = zone_y + 2.0 * cm -> change to zone_y + 0.5 * cm
text = re.sub(r'cachet_nom_y\s*=\s*zone_y\s*\+\s*2\.0\s*\*\s*cm', 'cachet_nom_y = zone_y + 0.5 * cm', text)
# In _draw_residence_pdf_content, it was:
# CACHET_NOM_Y = SIG_IMG_Y + 0.2*cm. The signature was SIG_IMG_Y. Let's make CACHET_NOM_Y = SIG_IMG_Y - 0.5 * cm
text = re.sub(r'CACHET_NOM_Y\s*=\s*SIG_IMG_Y\s*\+\s*0\.2\s*\*\s*cm', 'CACHET_NOM_Y = SIG_IMG_Y - 0.5 * cm', text)

# Let's add the "Validité : 3 mois..." in _draw_residence_pdf_content
# Find QR_TEXT_Y + 0.1*cm...
residence_addition = """    p.drawCentredString(width / 2, QR_TEXT_Y + 0.1*cm, "Scannez pour vérifier l'authenticité de ce document")

    p.setFont("Helvetica-Bold", 10)
    p.setFillColor(ROUGE)
    p.drawString(2 * cm, 1.5 * cm, "Validité : 3 mois à compter de la date de délivrance")
"""
text = text.replace('    p.drawCentredString(width / 2, QR_TEXT_Y + 0.1*cm, "Scannez pour v\\u00e9rifier l\'authenticit\\u00e9 de ce document")', residence_addition)
text = text.replace('    p.drawCentredString(width / 2, QR_TEXT_Y + 0.1*cm, "Scannez pour vérifier l\'authenticité de ce document")', residence_addition)

# Let's add "En foi de quoi..." in _draw_mariage_pdf_content
mariage_addition = """    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)
    y_body -= para_concl.height + 0.8 * cm

    p.setFont("Helvetica", 11)
    p.drawString(2 * cm, y_body, "En foi de quoi, nous avons délivré le présent certificat pour servir et valoir ce que de droit.")
    y_body -= 1.0 * cm  # Dégager de l'espace après la ligne

    # ======= RÉORGANISATION EN 5 ZONES SÉPARÉES =======
"""
text = re.sub(r'    para_concl\.drawOn\(p,\s*2\s*\*\s*cm,\s*y_body\s*-\s*para_concl\.height\)\n\s*y_body\s*-=\s*para_concl\.height\s*\+\s*1\.2\s*\*\s*cm\n\n\s*# ======= RÉORGANISATION EN 5 ZONES SÉPARÉES =======', mariage_addition, text)

# Add _draw_secure_timbre back inside pdf_generator.py if not exists
timbre_def = """def _draw_secure_timbre(p, x, y, reference):
    from reportlab.lib.colors import HexColor
    from reportlab.lib.units import cm
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

"""

if '_draw_secure_timbre' not in text:
    text = text.replace('def _draw_placeholder_seal', timbre_def + 'def _draw_placeholder_seal')


with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Fix applied.")
