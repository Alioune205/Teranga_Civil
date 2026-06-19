import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.dossiers.services.pdf_generator import generate_signed_certificate

def test_all():
    communes = Commune.objects.all()
    if not communes.exists():
        print("Aucune commune trouvée.")
        return

    # Create a dummy user
    citizen, _ = User.objects.get_or_create(email="testcitizen@example.com", defaults={"password": "pwd", "first_name": "Jean", "last_name": "Diop"})
    
    # Run for each commune
    for commune in communes:
        print(f"=== Génération pour {commune.name} ===")
        # Create a dummy dossier
        dossier = Dossier.objects.create(
            citizen=citizen,
            commune=commune,
            type=Dossier.Type.RESIDENCE_CERTIFICATE,
            status=Dossier.Status.APPROVED,
            metadata={"nom": "Diop", "prenoms": "Jean", "date_naissance": "1990-01-01", "lieu_naissance": "Dakar"}
        )
        try:
            cert = generate_signed_certificate(dossier, officier=None)
            print(f"Certificat généré : {cert.pdf_file.name}")
        except Exception as e:
            print(f"Erreur : {e}")

if __name__ == '__main__':
    test_all()
