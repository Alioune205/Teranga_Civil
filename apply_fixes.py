import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix 1: Adjust y_reg
text = re.sub(r'y_reg\s*=\s*height\s*-\s*6\.5\s*\*\s*cm', 'y_reg = height - 6.0 * cm', text)
# y_titre is already height - 8.5 * cm, which means spacing to height-7.4 is 1.1cm.

# Fix 2: Adjust zone_y minimum to 1.5 * cm
text = re.sub(r'zone_y\s*=\s*min\(1\.0\s*\*\s*cm,\s*y_body\s*-\s*9\.5\s*\*\s*cm\)', 'zone_y = min(1.5 * cm, y_body - 9.5 * cm)', text)

# Fix 3: Parents' names
# For Epoux
replace_epoux_parents = """    mari_pere_prenom = metadata.get('prenom_pere_epoux', 'Non précisé')
    mari_pere_nom = metadata.get('nom_pere_epoux', '')
    mari_pere = f"{mari_pere_prenom} {mari_pere_nom}".strip()
    mari_mere_prenom = metadata.get('prenom_mere_epoux', 'Non précisé')
    mari_mere_nom = metadata.get('nom_mere_epoux', '')
    mari_mere = f"{mari_mere_prenom} {mari_mere_nom}".strip()"""
    
text = re.sub(r"    mari_pere\s*=\s*metadata\.get\('prenom_pere_epoux',\s*'Non précisé'\)\n\s*mari_mere\s*=\s*metadata\.get\('prenom_mere_epoux',\s*'Non précisé'\)", replace_epoux_parents, text)

# For Epouse
replace_epouse_parents = """    epouse_pere_prenom = metadata.get('prenom_pere_epouse', 'Non précisé')
    epouse_pere_nom = metadata.get('nom_pere_epouse', '')
    epouse_pere = f"{epouse_pere_prenom} {epouse_pere_nom}".strip()
    epouse_mere_prenom = metadata.get('prenom_mere_epouse', 'Non précisé')
    epouse_mere_nom = metadata.get('nom_mere_epouse', '')
    epouse_mere = f"{epouse_mere_prenom} {epouse_mere_nom}".strip()"""

text = re.sub(r"    epouse_pere\s*=\s*metadata\.get\('prenom_pere_epouse',\s*'Non précisé'\)\n\s*epouse_mere\s*=\s*metadata\.get\('prenom_mere_epouse',\s*'Non précisé'\)", replace_epouse_parents, text)

# Also reduce inter-paragraph spacings a tiny bit more just in case
text = text.replace('y_body -= para_intro.height + 0.4 * cm', 'y_body -= para_intro.height + 0.3 * cm')
text = text.replace('y_body -= para_epouse.height + 0.4 * cm', 'y_body -= para_epouse.height + 0.3 * cm')
text = text.replace('y_body -= para_concl.height + 0.4 * cm', 'y_body -= para_concl.height + 0.3 * cm')
text = text.replace('y_body -= 0.8 * cm  # Dégager de l\'espace après la ligne', 'y_body -= 0.6 * cm  # Dégager de l\'espace après la ligne')

with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Updates applied to pdf_generator.py")
