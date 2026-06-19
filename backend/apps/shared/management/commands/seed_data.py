"""
seed_data.py — Commande de seed initiale pour Teranga Civil.
Crée les communes, utilisateurs, dossiers de test et les RegistreCivil
avec TOUS les champs renseignés pour tester l'enrichissement complet en local.

Fix bilan intégration 14/06 :
  - Ajout du RegistreCivil 100/2000 (remplace le 101/1998 incomplet)
  - Registres avec sexe, lieu_naissance, nom_pere, nom_mere, professions
"""
import random
from datetime import date
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.communes.models import Commune
from apps.dossiers.models import Dossier, RegistreCivil

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds the database with initial test data'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding data...')

        # 1. Communes
        communes_data = [
            {'name': 'Dakar Plateau', 'region': 'Dakar', 'department': 'Dakar', 'code': 'DK-PLT'},
            {'name': 'Médina', 'region': 'Dakar', 'department': 'Dakar', 'code': 'DK-MED'},
            {'name': 'Pikine', 'region': 'Dakar', 'department': 'Pikine', 'code': 'DK-PIK'},
            {'name': 'Rufisque', 'region': 'Dakar', 'department': 'Rufisque', 'code': 'DK-RUF'},
            {'name': 'Saint-Louis', 'region': 'Saint-Louis', 'department': 'Saint-Louis', 'code': 'SL-STL'},
            {'name': 'Thiès', 'region': 'Thiès', 'department': 'Thiès', 'code': 'TH-THI'},
        ]

        communes = []
        for c_data in communes_data:
            commune, created = Commune.objects.get_or_create(code=c_data['code'], defaults=c_data)
            communes.append(commune)
            if created:
                self.stdout.write(self.style.SUCCESS(f"Created commune: {commune.name}"))

        dakar_plateau = communes[0]

        # 2. Utilisateurs
        users_data = [
            {'email': 'superadmin@sunucivil.sn', 'role': User.Role.SUPER_ADMIN, 'first_name': 'Super', 'last_name': 'Admin', 'is_staff': True, 'is_superuser': True, 'is_verified': True, 'commune': None},
            {'email': 'admin.plateau@sunucivil.sn', 'role': User.Role.CIVIL_ADMIN, 'first_name': 'Maire', 'last_name': 'Plateau', 'is_staff': True, 'is_verified': True, 'commune': dakar_plateau},
            {'email': 'verifier.plateau@sunucivil.sn', 'role': User.Role.VERIFICATION_AGENT, 'first_name': 'Agent', 'last_name': 'Verif', 'is_staff': True, 'is_verified': True, 'commune': dakar_plateau},
            {'email': 'reception.plateau@sunucivil.sn', 'role': User.Role.RECEPTION_AGENT, 'first_name': 'Agent', 'last_name': 'Recept', 'is_staff': True, 'is_verified': True, 'commune': dakar_plateau},
            {'email': 'citoyen1@gmail.com', 'role': User.Role.CITIZEN, 'first_name': 'Moussa', 'last_name': 'Diop', 'phone': '+221771234567', 'is_verified': True, 'commune': dakar_plateau},
            {'email': 'citoyen2@gmail.com', 'role': User.Role.CITIZEN, 'first_name': 'Awa', 'last_name': 'Fall', 'phone': '+221779876543', 'is_verified': True, 'commune': dakar_plateau},
        ]

        citizens = []
        agents = []

        for u_data in users_data:
            email = u_data['email']
            user = User.objects.filter(email=email).first()
            if not user:
                commune = u_data.pop('commune')
                is_staff = u_data.pop('is_staff', False)
                is_superuser = u_data.pop('is_superuser', False)

                if is_superuser:
                    user = User.objects.create_superuser(password='password123', **u_data)
                else:
                    user = User.objects.create_user(password='password123', **u_data)

                user.is_staff = is_staff
                user.commune = commune
                user.save()

                if user.role == User.Role.CITIZEN:
                    profile = user.profile
                    profile.cni_number = f"1{''.join([str(random.randint(0,9)) for _ in range(12)])}"
                    profile.address = f"Rue {random.randint(1, 100)}, {commune.name if commune else 'Dakar'}"
                    profile.save()

                self.stdout.write(self.style.SUCCESS(f"Created user: {user.email} ({user.role})"))

            if user.role == User.Role.CITIZEN:
                citizens.append(user)
            else:
                agents.append(user)

        # 3. Dossiers
        if citizens and dakar_plateau:
            dossiers_data = [
                {'citizen': citizens[0], 'commune': dakar_plateau, 'type': Dossier.Type.BIRTH_CERTIFICATE, 'status': Dossier.Status.COMPLETED, 'notes': 'Demande traitée rapidement.'},
                {'citizen': citizens[0], 'commune': dakar_plateau, 'type': Dossier.Type.RESIDENCE_CERTIFICATE, 'status': Dossier.Status.IN_REVIEW},
                {'citizen': citizens[1], 'commune': dakar_plateau, 'type': Dossier.Type.MARRIAGE_CERTIFICATE, 'status': Dossier.Status.SUBMITTED},
                {'citizen': citizens[1], 'commune': dakar_plateau, 'type': Dossier.Type.BIRTH_CERTIFICATE, 'status': Dossier.Status.DRAFT},
            ]

            verifier = next((a for a in agents if a.role == User.Role.VERIFICATION_AGENT), None)

            for d_data in dossiers_data:
                if not Dossier.objects.filter(citizen=d_data['citizen'], type=d_data['type']).exists():
                    dossier = Dossier.objects.create(**d_data)
                    if dossier.status == Dossier.Status.COMPLETED:
                        dossier.submitted_at = timezone.now()
                        dossier.reviewed_at = timezone.now()
                        dossier.completed_at = timezone.now()
                        dossier.assigned_agent = verifier
                    elif dossier.status == Dossier.Status.IN_REVIEW:
                        dossier.submitted_at = timezone.now()
                        dossier.reviewed_at = timezone.now()
                        dossier.assigned_agent = verifier
                    elif dossier.status == Dossier.Status.SUBMITTED:
                        dossier.submitted_at = timezone.now()
                    dossier.save()
                    self.stdout.write(self.style.SUCCESS(
                        f"Created dossier: {dossier.reference} ({dossier.get_type_display()})"
                    ))

        # 4. RegistreCivil — Fix bilan intégration 14/06
        # Le registre 101/1998 était incomplet (nom + date seulement).
        # On crée 100/2000 et 101/2000 avec tous les champs pour tester
        # l'enrichissement complet (sexe, lieu, parents, professions).
        registres_data = [
            {
                'numero_registre': '100',
                'annee_registre': 2000,
                'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
                'commune': dakar_plateau,
                'nom_complet_personne': 'Moussa Diop',
                'date_naissance_personne': date(2000, 3, 15),
                'sexe': 'M',
                'lieu_naissance': 'Dakar',
                'nom_pere': 'Ibrahim Diop',
                'nom_mere': 'Aminata Sall',
                'profession_pere': 'Enseignant',
                'profession_mere': 'Infirmière',
            },
            {
                'numero_registre': '101',
                'annee_registre': 2000,
                'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
                'commune': dakar_plateau,
                'nom_complet_personne': 'Awa Fall',
                'date_naissance_personne': date(2000, 7, 22),
                'sexe': 'F',
                'lieu_naissance': 'Pikine',
                'nom_pere': 'Mamadou Fall',
                'nom_mere': 'Rokhaya Ndiaye',
                'profession_pere': 'Commerçant',
                'profession_mere': 'Couturière',
            },
        ]

        for reg_data in registres_data:
            registre, created = RegistreCivil.objects.get_or_create(
                numero_registre=reg_data['numero_registre'],
                annee_registre=reg_data['annee_registre'],
                commune=reg_data['commune'],
                type_acte=reg_data['type_acte'],
                defaults=reg_data,
            )
            if created:
                self.stdout.write(self.style.SUCCESS(
                    f"Created RegistreCivil: {registre.numero_registre}/{registre.annee_registre} "
                    f"— {registre.nom_complet_personne}"
                ))
            else:
                # Compléter les champs manquants si le registre existait déjà incomplet
                updated = False
                for field in ['sexe', 'lieu_naissance', 'nom_pere', 'nom_mere', 'profession_pere', 'profession_mere']:
                    if not getattr(registre, field, None) and reg_data.get(field):
                        setattr(registre, field, reg_data[field])
                        updated = True
                if updated:
                    registre.save()
                    self.stdout.write(self.style.SUCCESS(
                        f"Updated RegistreCivil: {registre.numero_registre}/{registre.annee_registre} (champs complétés)"
                    ))
                else:
                    self.stdout.write(f"  RegistreCivil {registre.numero_registre}/{registre.annee_registre} already complete.")

        self.stdout.write(self.style.SUCCESS('Database seeding completed successfully!'))
        self.stdout.write(self.style.WARNING('All passwords are: password123'))
