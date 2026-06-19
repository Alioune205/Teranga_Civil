import os
import re

addon_dir = r"C:\Program Files\Odoo\addons_su\isep_attestation_honneur"

# 1. Fix manifest
manifest_path = os.path.join(addon_dir, "__manifest__.py")
if os.path.exists(manifest_path):
    with open(manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("'version': '16.0.1.0.0'", "'version': '17.0.1.0.0'")
    
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Manifest fixed.")

# 2. Fix attrs in views
views_path = os.path.join(addon_dir, "views", "attestation_views.xml")
if os.path.exists(views_path):
    with open(views_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace attrs="{'invisible': [('state', 'in', ['valide', 'annule'])]}"
    content = content.replace("attrs=\"{'invisible': [('state', 'in', ['valide', 'annule'])]}\"", "invisible=\"state in ['valide', 'annule']\"")
    content = content.replace("attrs=\"{'invisible': [('state', '!=', 'valide')]}\"", "invisible=\"state != 'valide'\"")
    content = content.replace("attrs=\"{'invisible': [('state', 'in', ['annule'])]}\"", "invisible=\"state == 'annule'\"")
    content = content.replace("attrs=\"{'invisible': [('state', '!=', 'annule')]}\"", "invisible=\"state != 'annule'\"")
    
    with open(views_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Views fixed.")

print("All done.")
