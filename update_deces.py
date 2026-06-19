import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Extract the new footer block from Mariage
match_footer = re.search(r'(# ======= NOUVELLE RÉORGANISATION EN 2 LIGNES SUPERPOSÉES =======.*?)(?=\n\n\s*def _draw_deces_pdf_content)', text, re.DOTALL)
if match_footer:
    new_footer = match_footer.group(1)
    
    # Replace the old 5 ZONES block in Deces
    # Deces 5 zones starts with: # ---------------- 5 ZONES DE VALIDATION (Réutilisées) ----------------
    # Ends before def _draw_pdf_content
    old_deces_footer = re.search(r'(# ---------------- 5 ZONES DE VALIDATION \(Réutilisées\) ----------------.*?)(?=\n\n\s*def _draw_pdf_content)', text, re.DOTALL)
    
    if old_deces_footer:
        # Before replacing, let's make sure the indentation matches if needed.
        # It's indented 4 spaces. Same as Mariage.
        text = text.replace(old_deces_footer.group(1), new_footer)
        
        with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
            f.write(text)
        print("Updated Deces footer!")
    else:
        print("Could not find old Deces footer.")
else:
    print("Could not find new Mariage footer.")
