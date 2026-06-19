import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import RegistreCivil
from apps.etat_civil.models_citoyen import Citoyen

def create_demo_users():
    # S'assure qu'une commune existe avec le code utilisé par le frontend
    commune, _ = Commune.objects.get_or_create(
        code="DKR-PLT", 
        defaults={"name": "Dakar Plateau", "region": "Dakar"}
    )
    print(f"Commune '{commune.name}' prete.")

    demo_data = [
        {
            'email': 'amadou@teranga.sn',
            'phone': '+221771112233',
            'first_name': 'Amadou',
            'last_name': 'Diallo',
            'password': 'passer123',
            'date_naissance': '1995-05-10',
            'lieu_naissance': 'Dakar',
            'sexe': 'Masculin',
            'numero_registre': '12345',
            'annee_registre': 1995,
            'prenom_pere': 'Mamadou',
            'prenom_mere': 'Fatou',
            'nom_mere': 'Sow',
        },
        {
            'email': 'awa@teranga.sn',
            'phone': '+221774445566',
            'first_name': 'Awa',
            'last_name': 'Ndiaye',
            'password': 'passer123',
            'date_naissance': '1998-11-20',
            'lieu_naissance': 'Dakar Plateau',
            'sexe': 'Féminin',
            'numero_registre': '67890',
            'annee_registre': 1998,
            'prenom_pere': 'Cheikh',
            'prenom_mere': 'Aissatou',
            'nom_mere': 'Fall',
        },
        {
            'email': 'moussa@teranga.sn',
            'phone': '+221777889900',
            'first_name': 'Moussa',
            'last_name': 'Sow',
            'password': 'passer123',
            'date_naissance': '2001-02-14',
            'lieu_naissance': 'Dakar',
            'sexe': 'Masculin',
            'numero_registre': '54321',
            'annee_registre': 2001,
            'prenom_pere': 'Ousmane',
            'prenom_mere': 'Mariama',
            'nom_mere': 'Diop',
        }
    ]

    for data in demo_data:
        # 1. Créer ou mettre à jour le Compte Utilisateur (Mobile/Web)
        user, user_created = User.objects.get_or_create(
            email=data['email'],
            defaults={
                'phone': data['phone'],
                'first_name': data['first_name'],
                'last_name': data['last_name'],
                'role': User.Role.CITIZEN,
                'commune': commune,
                'is_verified': True
            }
        )
        if user_created:
            user.set_password(data['password'])
            user.save()
            print(f"Utilisateur cree : {data['first_name']} {data['last_name']}")

        # 2. Créer ou mettre à jour le Registre Civil (Base de données nationale)
        registre, reg_created = RegistreCivil.objects.get_or_create(
            numero_registre=data['numero_registre'],
            annee_registre=data['annee_registre'],
            commune=commune,
            type_acte='birth_certificate',
            defaults={
                'nom_complet_personne': f"{data['first_name']} {data['last_name']}",
                'date_naissance_personne': data['date_naissance'],
            }
        )
        if reg_created:
            print(f"Acte de naissance ajoute au registre : {data['numero_registre']}/{data['annee_registre']}")

        # 3. Créer le profil Citoyen si nécessaire
        Citoyen.objects.get_or_create(
            prenom=data['first_name'],
            nom=data['last_name'],
            telephone=data['phone'],
            defaults={
                'date_naissance': data['date_naissance'],
                'sexe': data['sexe'][0], # 'M' ou 'F'
                'commune': commune,
                'lieu_naissance': data['lieu_naissance'],
            }
        )

    print(f"\nTermine ! Les donnees sont pretes pour les tests.")

if __name__ == '__main__':
    create_demo_users()
