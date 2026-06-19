import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the overlap in Death Certificate
old_deces = """    para_intro.drawOn(p, 4 * cm, y_body - para_intro.height)
    
    # ---------------- CONCLUSION ----------------
    y_body -= 1.5 * cm
    texte_concl = "Le présent certificat est délivré à l'intéressé(e) ou à ses ayants droit pour servir et valoir ce que de droit."
    para_concl = Paragraph(texte_concl, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)
    y_body -= para_concl.height + 0.8 * cm"""

new_deces = """    para_intro.drawOn(p, 4 * cm, y_body - para_intro.height)
    
    # ---------------- CONCLUSION ----------------
    y_body -= para_intro.height + 0.5 * cm
    texte_concl = "Le présent certificat est délivré à l'intéressé(e) ou à ses ayants droit pour servir et valoir ce que de droit."
    para_concl = Paragraph(texte_concl, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)
    y_body -= para_concl.height + 0.5 * cm"""

if old_deces in text:
    text = text.replace(old_deces, new_deces)
    with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
        f.write(text)
    print("Fixed overlap in Deces")
else:
    print("Could not find the target string in Deces")

