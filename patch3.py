import os

path = r"backend\apps\dossiers\models.py"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Add citoyen_guichet back to Dossier model
import re
pattern = r"(citizen = models\.ForeignKey\([\s\S]*?verbose_name='Citoyen',\s*\))"
replacement = r"""\1
    citoyen_guichet = models.ForeignKey(
        'etat_civil.Citoyen',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='dossiers',
        verbose_name='Citoyen (Guichet)',
    )"""

content = re.sub(pattern, replacement, content)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("citoyen_guichet restored")
