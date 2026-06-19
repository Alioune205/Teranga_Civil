import os
import random
import uuid
from datetime import timedelta
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.db import transaction

from apps.communes.models import Commune
from apps.users.models import User
from apps.etat_civil.models_citoyen import Citoyen
from apps.dossiers.models import Dossier, RegistreCivil
from apps.documents.models import Document
from apps.payments.models import PaymentTransaction, PaymentStatus, PaymentType
from apps.audit_logs.models import AuditLog

# Configuration des communes
COMMUNES_DATA = [
    {"code": "DKR-PLT", "name": "Dakar Plateau", "region": "Dakar", "department": "Dakar"},
    {"code": "DKR-KMS", "name": "Keur Massar", "region": "Dakar", "department": "Keur Massar"},
    {"code": "THI-THI", "name": "Thiès", "region": "Thiès", "department": "Thiès"},
    {"code": "THI-NDG", "name": "Ndiaganiao", "region": "Thiès", "department": "M'bour"},
    {"code": "STL-STL", "name": "Saint-Louis", "region": "Saint-Louis", "department": "Saint-Louis"},
]

FIRST_NAMES_M = ["Amadou", "Moussa", "Cheikh", "Ousmane", "Modou", "Pape", "Ibrahima", "Alioune", "Babacar", "Lamine"]
FIRST_NAMES_F = ["Awa", "Fatou", "Aminata", "Ndeye", "Mariama", "Aissatou", "Khadija", "Oumy", "Coumba", "Binta"]
LAST_NAMES = ["Diop", "Ndiaye", "Fall", "Sow", "Diallo", "Ba", "Faye", "Gueye", "Seck", "Mbodj", "Cisse", "Thiam"]

PROFESSIONS = ["Enseignant", "Commerçant", "Médecin", "Ingénieur", "Ménagère", "Etudiant", "Menuisier", "Chauffeur"]
QUARTIERS = ["Médina", "Grand Yoff", "Almadies", "HLM", "Parcelles Assainies", "Pikine", "Guediawaye", "Fass", "Point E"]

def random_phone():
    return f"+2217{random.choice(['7','6','8','0'])}{random.randint(1000000, 9999999)}"

def random_cni():
    return f"{random.choice(['1','2'])}{random.randint(100,999)}{random.randint(1000,9999)}{random.randint(10000,99999)}"

from django.core.management import call_command

class Command(BaseCommand):
    help = "Peuple la base de données avec un jeu de données réaliste pour Teranga Civil"

    def add_arguments(self, parser):
        parser.add_argument('--flush', action='store_true', help='Vider les données de test existantes avant de repeupler')

    def handle(self, *args, **options):
        if options['flush']:
            self.stdout.write(self.style.WARNING("Flushing existing data using Django flush..."))
            call_command('flush', interactive=False)
            self.stdout.write(self.style.SUCCESS("Data flushed!"))

        self._seed_data()
            
    def _seed_data(self):
        now = timezone.now()
        communes = []
        
        # 1. Communes
        for c_data in COMMUNES_DATA:
            commune, _ = Commune.objects.update_or_create(
                code=c_data["code"],
                defaults={
                    "name": c_data["name"],
                    "region": c_data["region"],
                    "department": c_data["department"],
                    "nom_officier_etat_civil": f"{random.choice(FIRST_NAMES_M)} {random.choice(LAST_NAMES)}",
                    "address": f"Mairie de {c_data['name']}",
                    "is_active": True,
                }
            )
            communes.append(commune)
        self.stdout.write(f"Créé {len(communes)} communes.")

        # 2. Comptes Utilisateurs
        users_created = 0
        superadmin, _ = User.objects.get_or_create(email="superadmin@test.local", defaults={
            "first_name": "Super", "last_name": "Admin", "role": User.Role.SUPER_ADMIN, "is_superuser": True, "is_staff": True, "is_verified": True
        })
        superadmin.set_password("pass")
        superadmin.save()
        users_created += 1

        all_agents = []
        for commune in communes:
            slug = commune.name.lower().replace(" ", "").replace("'", "").replace("-", "")
            
            roles_to_create = [
                {"email": f"supervisor.{slug}@test.local", "role": User.Role.CIVIL_ADMIN_SUPERVISOR, "caps": []},
                {"email": f"civiladmin.{slug}@test.local", "role": User.Role.CIVIL_ADMIN, "caps": []},
                {"email": f"agent.reception.{slug}@test.local", "role": User.Role.AGENT, "caps": ["reception"]},
                {"email": f"agent.verification.{slug}@test.local", "role": User.Role.AGENT, "caps": ["verification"]},
                {"email": f"agent.approval.{slug}@test.local", "role": User.Role.AGENT, "caps": ["approval"]},
                {"email": f"agent.polyvalent.{slug}@test.local", "role": User.Role.AGENT, "caps": ["reception", "verification", "approval"]},
            ]
            
            for rc in roles_to_create:
                first = random.choice(FIRST_NAMES_M + FIRST_NAMES_F)
                last = random.choice(LAST_NAMES)
                user, created = User.objects.update_or_create(
                    email=rc["email"],
                    defaults={
                        "first_name": first, "last_name": last, "phone": random_phone(),
                        "role": rc["role"], "agent_capabilities": rc["caps"],
                        "commune": commune, "is_verified": True, "is_active": True
                    }
                )
                if created:
                    user.set_password("pass")
                    user.save()
                    users_created += 1
                if rc["role"] == User.Role.AGENT:
                    all_agents.append(user)

            # Extra agents for break/dispatch testing
            break_agent, _ = User.objects.update_or_create(
                email=f"agent.break.{slug}@test.local",
                defaults={
                    "first_name": "Agent", "last_name": "EnPause", "role": User.Role.AGENT, "agent_capabilities": ["reception"],
                    "commune": commune, "is_verified": True, "is_on_break": True, "break_started_at": now - timedelta(minutes=45)
                }
            )
            break_agent.set_password("pass")
            break_agent.save()
            users_created += 1
            
            nodispatch_agent, _ = User.objects.update_or_create(
                email=f"agent.nodispatch.{slug}@test.local",
                defaults={
                    "first_name": "Agent", "last_name": "NoDispatch", "role": User.Role.AGENT, "agent_capabilities": ["reception"],
                    "commune": commune, "is_verified": True, "is_dispatch_eligible": False
                }
            )
            nodispatch_agent.set_password("pass")
            nodispatch_agent.save()
            users_created += 1

        self.stdout.write(f"Créé/Mis à jour {users_created} utilisateurs internes.")

        # 3 & 4 & 5. Citoyens, Registre Civil, Dossiers
        all_citoyens = []
        registres = []
        dossiers_created = 0
        documents_created = 0
        transactions_created = 0

        for c_idx, commune in enumerate(communes):
            # 3. Citoyens (10 per commune)
            num_citoyens = 10
            for i in range(num_citoyens):
                sexe = random.choice(["M", "F"])
                first = random.choice(FIRST_NAMES_M if sexe == "M" else FIRST_NAMES_F)
                last = random.choice(LAST_NAMES)
                phone = f"77{c_idx+1}000{i:03d}"
                email = f"{phone}@terangacivil.sn"
                
                # Create User (Citizen)
                cit_user, _ = User.objects.update_or_create(
                    email=email,
                    defaults={
                        "first_name": first, "last_name": last, "phone": phone,
                        "role": User.Role.CITIZEN, "is_verified": True, "commune": commune
                    }
                )
                cit_user.set_password("passpass")
                cit_user.save()

                has_cni = random.random() < 0.7
                
                citoyen, _ = Citoyen.objects.update_or_create(
                    telephone=phone,
                    defaults={
                        "prenom": first, "nom": last, "sexe": sexe,
                        "date_naissance": (now - timedelta(days=random.randint(7000, 20000))).date(),
                        "lieu_naissance": commune.name, "commune": commune,
                        "numero_cni": random_cni() if has_cni else None,
                        "adresse": f"Quartier {random.choice(QUARTIERS)}",
                        "nom_pere": f"{random.choice(FIRST_NAMES_M)} {last}",
                        "nom_mere": f"{random.choice(FIRST_NAMES_F)} {random.choice(LAST_NAMES)}",
                    }
                )
                all_citoyens.append((cit_user, citoyen))

            # 4. Registre Civil (5 per commune)
            commune_registres = []
            for j in range(5):
                type_acte = random.choice(["birth_certificate", "death_certificate", "marriage_certificate"])
                nom_complet = f"{random.choice(FIRST_NAMES_M)} {random.choice(LAST_NAMES)}"
                
                reg, _ = RegistreCivil.objects.update_or_create(
                    numero_registre=f"REG-{commune.code}-{2024}-{j}",
                    annee_registre=2024,
                    commune=commune,
                    defaults={
                        "type_acte": type_acte,
                        "nom_complet_personne": nom_complet,
                        "date_naissance_personne": (now - timedelta(days=random.randint(1000, 15000))).date(),
                        "lieu_naissance": commune.name,
                        "sexe": random.choice(["M", "F"]),
                        "nom_pere": f"{random.choice(FIRST_NAMES_M)} {nom_complet.split(' ')[1]}",
                        "profession_pere": random.choice(PROFESSIONS),
                        "nom_mere": f"{random.choice(FIRST_NAMES_F)} {random.choice(LAST_NAMES)}",
                        "profession_mere": random.choice(PROFESSIONS),
                    }
                )
                commune_registres.append(reg)
                registres.append(reg)

            # 5. Dossiers (Variety)
            # Make sure we have 1 of each type and status per commune
            types = [c[0] for c in Dossier.Type.choices if c[0] != 'other']
            statuses = [c[0] for c in Dossier.Status.choices]
            commune_agents = [a for a in all_agents if a.commune == commune]

            for d_type in types:
                for d_status in statuses:
                    cit_user, citoyen = random.choice(all_citoyens)
                    # Assign a registre if matching type, else orphan
                    reg = next((r for r in commune_registres if r.type_acte == d_type), None)
                    if random.random() < 0.2:
                        reg = None # orphan dossier

                    is_late = False
                    sub_date = now - timedelta(days=random.randint(1, 3))
                    if d_status in ['submitted', 'in_review'] and random.random() < 0.3:
                        is_late = True
                        sub_date = now - timedelta(days=8)

                    dossier = Dossier.objects.create(
                        reference=f"DOS-{commune.code}-{uuid.uuid4().hex[:6].upper()}",
                        type=d_type,
                        status=d_status,
                        citizen=cit_user,
                        citoyen_guichet=citoyen,
                        commune=commune,
                        assigned_agent=random.choice(commune_agents) if commune_agents else None,
                        submitted_at=sub_date if d_status != 'draft' else None,
                        reviewed_at=sub_date + timedelta(days=1) if d_status in ['approved', 'rejected', 'completed'] else None,
                        completed_at=sub_date + timedelta(days=2) if d_status == 'completed' else None,
                        metadata={
                            "registre_id": str(reg.id) if reg else None,
                            "is_for_third_party": random.random() < 0.2
                        }
                    )
                    
                    # Force creation date for graph variability
                    dossier.created_at = sub_date - timedelta(days=1)
                    dossier.save()
                    dossiers_created += 1

                    # 6. Documents
                    if d_status not in ['draft', 'submitted']:
                        Document.objects.create(
                            dossier=dossier,
                            file="dummy_path.pdf",
                            original_filename=f"Document_{d_type}.pdf",
                            file_type="identite",
                            file_size=1024,
                            description="Pièce d'identité",
                            uploaded_by=cit_user
                        )
                        documents_created += 1

                    # 7. Transactions
                    if d_status in ['approved', 'completed', 'in_review']:
                        amount = 1000 if d_type == 'marriage_certificate' else 500
                        t_status = random.choice(['paid', 'pending', 'failed'])
                        if d_status == 'completed': t_status = 'paid'
                        
                        PaymentTransaction.objects.create(
                            reference=f"PAY-{uuid.uuid4().hex[:8].upper()}",
                            dossier=dossier,
                            amount=amount,
                            payment_type=PaymentType.ORANGE_MONEY,
                            status=t_status,
                            payer_name=citoyen.nom_complet if hasattr(citoyen, 'nom_complet') else f"{citoyen.prenom} {citoyen.nom}",
                            payer_id=citoyen.telephone,
                            service_label=f"Paiement pour {dossier.get_type_display()}"
                        )
                        transactions_created += 1

        self.stdout.write(f"Créé {len(all_citoyens)} citoyens.")
        self.stdout.write(f"Créé {len(registres)} registres d'état civil.")
        self.stdout.write(f"Créé {dossiers_created} dossiers.")
        self.stdout.write(f"Créé {documents_created} documents.")
        self.stdout.write(f"Créé {transactions_created} transactions.")

        # 8. Audit Logs
        actions = ["login", "create_dossier", "update_status", "download_pdf", "logout"]
        for _ in range(50):
            user = random.choice([superadmin] + all_agents)
            log_date = now - timedelta(days=random.randint(0, 14), hours=random.randint(0, 23))
            AuditLog.objects.create(
                user=user,
                action=random.choice(actions),
                resource_type="System" if user == superadmin else "Dossier",
                resource_id=str(uuid.uuid4()),
                ip_address=f"192.168.1.{random.randint(1, 254)}",
                details={"info": "Seeded log entry"}
            )
            # Force timestamp
            AuditLog.objects.filter(id=AuditLog.objects.latest('created_at').id).update(created_at=log_date)

        self.stdout.write(f"Créé 50 logs d'audit.")
        
        self.stdout.write(self.style.SUCCESS("\n============================================="))
        self.stdout.write(self.style.SUCCESS("Succès : Base de données peuplée avec succès !"))
        self.stdout.write(self.style.SUCCESS("============================================="))
        self.stdout.write(f"Communes: {len(communes)}")
        self.stdout.write(f"Utilisateurs: {users_created}")
        self.stdout.write(f"Citoyens: {len(all_citoyens)}")
        self.stdout.write(f"Dossiers: {dossiers_created}")
        self.stdout.write(f"Transactions: {transactions_created}")
        self.stdout.write("Tous les mots de passe sont : passpass")
