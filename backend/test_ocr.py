"""
Script de test OCR — supporte image ET PDF.
Usage :
    python test_ocr.py              → teste avec test.jpg
    python test_ocr.py test.pdf     → teste avec un PDF
    python test_ocr.py mon_doc.png  → teste avec n'importe quelle image
"""
import sys
from apps.ai.ocr import extract_text_from_file, extract_cni_data

# Choisir le fichier à tester
fichier = sys.argv[1] if len(sys.argv) > 1 else "test.jpg"

print(f"\n{'='*50}")
print(f"  Fichier testé : {fichier}")
print(f"{'='*50}\n")

print("📄 Texte brut extrait :")
print("-" * 50)
text = extract_text_from_file(fichier)
print(text if text else "⚠️  Aucun texte extrait.")

print("\n" + "=" * 50)
print("🗂️  Données structurées CNI :")
print("-" * 50)
data = extract_cni_data(fichier)
for key, value in data.items():
    status = "✅" if value else "❌"
    print(f"  {status}  {key:<20} : {value or '(non trouvé)'}")
print()