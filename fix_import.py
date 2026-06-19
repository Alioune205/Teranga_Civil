import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('        from reportlab.lib.utils import ImageReader', '')

with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Fixed ImageReader import issue")
