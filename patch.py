import os

path = r"backend\apps\dossiers\services\pdf_generator.py"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix Deces (remove the accidentally injected Validité 3 mois)
deces_bad = '''    # MENTION DE VALIDITÉ 3 MOIS
    y_body -= para_intro.height + 1.5 * cm
    p.setFont("Helvetica-BoldOblique", 11)
    p.drawCentredString(width / 2, y_body, "Validité : 3 mois à compter de la date de délivrance.")
    
    y_body -= 1.0 * cm
    p.setFont("Helvetica", 12)
    texte_concl = "Le présent certificat est délivré à l'intéressé(e) ou à ses ayants droit pour servir et valoir ce que de droit."
    p.drawCentredString(width / 2, y_body, texte_concl)
    para_concl = Paragraph(texte_concl, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)'''

deces_good = '''    # ---------------- CONCLUSION ----------------
    y_body -= 1.5 * cm
    texte_concl = "Le présent certificat est délivré à l'intéressé(e) ou à ses ayants droit pour servir et valoir ce que de droit."
    para_concl = Paragraph(texte_concl, style_normal)
    para_concl.wrap(width - 4 * cm, 5 * cm)
    para_concl.drawOn(p, 2 * cm, y_body - para_concl.height)'''

content = content.replace(deces_bad, deces_good)

# Add to Residence
residence_old = '''    para_intro = Paragraph(texte_central, style_normal)
    para_intro.wrap(width - 8 * cm, 10 * cm)
    para_intro.drawOn(p, 4 * cm, y_body - para_intro.height)
    
    y_body -= para_intro.height + 1.0 * cm
    p.setFont("Helvetica", 12)
    texte_concl = "En foi de quoi le présent certificat est délivré pour servir et valoir ce que de droit."
    p.drawCentredString(width / 2, y_body, texte_concl)'''

residence_new = '''    para_intro = Paragraph(texte_central, style_normal)
    para_intro.wrap(width - 8 * cm, 10 * cm)
    para_intro.drawOn(p, 4 * cm, y_body - para_intro.height)
    
    # MENTION DE VALIDITÉ 3 MOIS
    y_body -= para_intro.height + 1.5 * cm
    p.setFont("Helvetica-BoldOblique", 11)
    p.drawCentredString(width / 2, y_body, "Validité : 3 mois à compter de la date de délivrance.")
    
    y_body -= 1.0 * cm
    p.setFont("Helvetica", 12)
    texte_concl = "En foi de quoi le présent certificat est délivré pour servir et valoir ce que de droit."
    p.drawCentredString(width / 2, y_body, texte_concl)'''

content = content.replace(residence_old, residence_new)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("PATCHED")
