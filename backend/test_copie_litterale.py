import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.dossiers.services.pdf_generators.copie_litterale_naissance import generer_copie_litterale_naissance
from rest_framework.exceptions import ValidationError

class MockCommune:
    region = "Dakar"
    department = "Dakar"
    name = "Dakar Plateau"

class MockDossier:
    def __init__(self, citizen=None, status='completed'):
        self.citizen = citizen
        self.status = status
        self.commune = MockCommune()
        self.metadata = {
            'numero_registre': '1234',
            'annee_registre': '2026',
            'prenoms_enfant': 'Alioune',
            'nom_enfant': 'NDIAYE',
            'date_naissance_personne': '12/04/1990',
            'heure_naissance': '14:30',
            'lieu_naissance_enfant': 'Maternité de Fann',
            'sexe': 'Masculin',
            'prenom_pere': 'Oumar',
            'nom_pere': 'NDIAYE',
            'profession_pere': 'Enseignant',
            'adresse_pere': 'Point E, Dakar',
            'prenom_mere': 'Fatou',
            'nom_mere': 'FALL',
            'statut_matrimonial_mere': 'Son épouse',
            'adresse_mere': 'Point E, Dakar',
            'nom_declarant': 'Oumar NDIAYE',
            'officier_nom': 'Amadou SECK'
        }
        self.citoyen_guichet = None
        self.completed_at = None

class MockOfficier:
    full_name = "Amadou SECK"

def test_hasattr_none():
    print("--- TEST hasattr(None, 'profile') ---")
    dossier = MockDossier(citizen=None)
    try:
        # User's question: "confirme dans ton script de test local que hasattr(dossier.citizen, 'profile') ne lève pas d'exception quand dossier.citizen est None"
        result = hasattr(dossier.citizen, 'profile')
        print(f"hasattr(None, 'profile') a retourné : {result} sans lever d'exception.")
    except Exception as e:
        print(f"Exception levée : {e}")
    print("--------------------------------------\n")

def test_generation():
    print("--- TEST GÉNÉRATION COPIE LITTÉRALE ---")
    dossier = MockDossier(citizen=None, status='completed')
    officier = MockOfficier()
    
    try:
        cachet_path = 'assets/seals/dakar_plateau/Cachet_Communal_Commune_De_Dakar_Plateau.png'
        signature_path = 'assets/seals/dakar_plateau/Signarure_Officier_Etat_Civil_El_hadji_Idrissa_Ndiaye_Dakar_Plateau.png'
        cachet_nominal_path = 'assets/seals/dakar_plateau/Cachet_Nominal_Officier_Etat_Civil_El_hadji_Idrissa_Ndiaye_Dakar_Plateau.png'
        buffer = generer_copie_litterale_naissance(dossier, officier, cachet_path, signature_path, cachet_nominal_path)
        output_path = 'copie_litterale_test.pdf'
        with open(output_path, 'wb') as f:
            f.write(buffer.getvalue())
        print(f"PDF généré avec succès : {os.path.abspath(output_path)}")
        
        # Test statut non complété
        dossier_draft = MockDossier(citizen=None, status='draft')
        try:
            generer_copie_litterale_naissance(dossier_draft, officier)
            print("ERREUR: La vérification de finalisation a échoué.")
        except ValidationError as e:
            print(f"SUCCÈS: La vérification de finalisation a fonctionné (Erreur 400). Message: {e}")
            
    except Exception as e:
        print(f"Erreur lors de la génération : {e}")

if __name__ == '__main__':
    test_hasattr_none()
    test_generation()

    # Convert to PNG for display
    import fitz
    if os.path.exists('copie_litterale_test.pdf'):
        doc = fitz.open('copie_litterale_test.pdf')
        page = doc.load_page(0)
        pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
        png_path = 'C:/Users/senep/.gemini/antigravity-ide/brain/6a753687-ccec-4af2-bd12-4e87afc342c3/copie_litterale_test.png'
        pix.save(png_path)
        print("PNG généré pour aperçu.")
