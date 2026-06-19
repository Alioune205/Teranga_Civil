import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace devise
content = content.replace('"Un Peuple - Un But - Une Foi"', 'dossier.commune.devise if dossier.commune and dossier.commune.devise else "Un Peuple - Un But - Une Foi"')

# Replace REGION DE
content = re.sub(r'f"REGION DE \{region\.upper\(\)\}"', 'f"REGION DE {dossier.commune.region.upper() if dossier.commune and dossier.commune.region else region.upper()}"', content)
content = re.sub(r'"REGION DE DAKAR"', 'f"REGION DE {dossier.commune.region.upper() if dossier.commune and dossier.commune.region else \\"DAKAR\\"}"', content)

with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
