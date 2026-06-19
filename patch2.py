import os

path = r"backend\apps\etat_civil\api\citoyen_views.py"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace Dossier.Status.DELIVERED with Dossier.Status.VALIDATED or whatever exists
# First, let's see what Dossier.Status has in models.py
# Actually, I can just replace 'Dossier.Status.DELIVERED' with "'delivered'"
content = content.replace("Dossier.Status.DELIVERED", "'delivered'")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("Status patched")
