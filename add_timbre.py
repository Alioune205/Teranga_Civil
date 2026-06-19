import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

timbre_def = """
def _draw_secure_timbre(p, x, y, reference):
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

# Insert right after the imports
match = re.search(r'import hashlib\n?', text)
if match:
    text = text[:match.end()] + timbre_def + text[match.end():]
else:
    print("Could not find import hashlib")

with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Timbre added.")
