import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from django.contrib.auth import get_user_model
from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.dossiers.services.pdf_generator import generate_signed_certificate
from apps.documents.models import GeneratedCertificate

User = get_user_model()

commune = Commune.objects.filter(code='DKR-PLT').first()
if not commune:
    print("Commune DKR-PLT non trouvée.")
    exit()

citizen, _ = User.objects.get_or_create(
    email='citizen@test.com',
    defaults={'first_name': 'Lansana', 'last_name': 'Coly', 'role': 'citizen', 'phone': '+221770000001'}
)

officier, _ = User.objects.get_or_create(
    email='officier@test.com',
    defaults={'first_name': 'El Hadji Idrissa', 'last_name': 'Ndiaye', 'role': 'civil_admin', 'phone': '+221770000002'}
)

dossier, created = Dossier.objects.get_or_create(
    reference='DOS-2026-3CD87',
    defaults={
        'citizen': citizen,
        'commune': commune,
        'type': 'birth_certificate',
        'status': 'in_review',
        'metadata': {
            'numero_registre': '2026-3CD87',
            'annee_registre': 2026,
            'prenoms_enfant': 'Alioune',
            'nom_enfant': 'Sène',
            'sexe': 'Masculin',
            'date_naissance_personne': '2000-01-01',
            'heure_naissance': '14:30',
            'lieu_naissance': 'Dakar Plateau',
            'prenom_pere': 'Amadou',
            'prenom_mere': 'Fatou',
            'nom_mere': 'Diop',
            'est_jugement_suppletif': False,
        }
    }
)

if not created:
    dossier.type = 'birth_certificate'
    dossier.metadata.update({
            'numero_registre': '2026-3CD87',
            'annee_registre': 2026,
            'prenoms_enfant': 'Alioune',
            'nom_enfant': 'Sène',
            'sexe': 'Masculin',
            'date_naissance_personne': '2000-01-01',
            'heure_naissance': '14:30',
            'lieu_naissance': 'Dakar Plateau',
            'prenom_pere': 'Amadou',
            'prenom_mere': 'Fatou',
            'nom_mere': 'Diop',
    })
    dossier.save()

try:
    GeneratedCertificate.objects.filter(dossier=dossier).delete()
    
    cert = generate_signed_certificate(dossier, officier)
    print("==================================================")
    print("SUCCES : PDF Genere !")
    print(f"Emplacement du fichier : {cert.pdf_file.path}")
    print(f"🔒 Signature HMAC : {cert.hmac_signature}")
    print("==================================================")
except Exception as e:
    import traceback
    traceback.print_exc()
    print(f"Erreur lors de la génération : {e}")
