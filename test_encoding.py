# -*- coding: utf-8 -*-
import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

replacements = {
    "%tat": "État",
    "%LECTRONIQUE": "ÉLECTRONIQUE",
    "complÃ¨te": "complète",
    "RǸf": "Réf",
    "sǸcurisǸ": "sécurisé",
    "d'Ǧtre": "d'être",
    "dessinǸ": "dessiné",
    "CrǸe": "Crée",
    "CrǸer": "Créer",
    "%": "É",
}

for k, v in replacements.items():
    text = text.replace(k, v)

with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Fix applied.")
