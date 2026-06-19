import random
from datetime import date, timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db.models.signals import post_save
from apps.users.models import User
from apps.communes.models import Commune
from apps.etat_civil.models_citoyen import Citoyen
from apps.dossiers.models import Dossier
from apps.etat_civil.signals_attribution import trigger_attribution_dossier

class Command(BaseCommand):
    help = 'Seed test citizens and supervisor accounts'

    def handle(self, *args, **kwargs):
        self.stdout.write("Starting seed_citoyens_test...")
        
        # Disconnect signal to avoid Redis connection errors during seeding
        post_save.disconnect(trigger_attribution_dossier, sender=Dossier)

        communes_data = [
            {"name": "Dakar Plateau", "email_supervisor": "supervisor.dakarplateau@test.local", "email_admin": "civiladmin.dakarplateau@test.local", "email_agent1": "agent1.dakarplateau@test.local", "email_agent2": "agent2.dakarplateau@test.local"},
            {"name": "Thiès", "email_supervisor": "supervisor.thies@test.local", "email_admin": "civiladmin.thies@test.local", "email_agent1": "agent1.thies@test.local", "email_agent2": "agent2.thies@test.local"},
            {"name": "Keur Massar", "email_supervisor": "supervisor.keurmassar@test.local", "email_admin": "civiladmin.keurmassar@test.local", "email_agent1": "agent1.keurmassar@test.local", "email_agent2": "agent2.keurmassar@test.local"},
        ]

        prenoms = ["Amadou", "Fatou", "Moussa", "Awa", "Ibrahima", "Ndeye", "Cheikh", "Aminata"]
        noms = ["Ndiaye", "Diop", "Fall", "Sarr", "Gueye", "Sow"]
        quartiers = ["Centre", "Nord", "Sud", "Est", "Ouest"]
        
        for cdata in communes_data:
            # Create or get commune
            commune, created = Commune.objects.get_or_create(
                name=cdata["name"],
                defaults={'region': 'Test Region', 'department': 'Test Dept'}
            )
            self.stdout.write(f"Commune {commune.name} ready.")

            # Create or get civil_admin_supervisor
            user_supervisor, created = User.objects.get_or_create(
                email=cdata["email_supervisor"],
                defaults={
                    'first_name': 'Supervisor',
                    'last_name': cdata["name"],
                    'role': 'civil_admin_supervisor',
                    'commune': commune,
                    'is_active': True,
                }
            )
            if created:
                user_supervisor.set_password("pass")
                user_supervisor.save()
            else:
                user_supervisor.role = 'civil_admin_supervisor'
                user_supervisor.commune = commune
                user_supervisor.set_password("pass")
                user_supervisor.save()
            self.stdout.write(f"Supervisor {user_supervisor.email} ready.")

            # Create or get civil_admin
            user_admin, created = User.objects.get_or_create(
                email=cdata["email_admin"],
                defaults={
                    'first_name': 'Admin',
                    'last_name': cdata["name"],
                    'role': 'civil_admin',
                    'commune': commune,
                    'is_active': True,
                }
            )
            if created:
                user_admin.set_password("pass")
                user_admin.save()
            else:
                user_admin.role = 'civil_admin'
                user_admin.commune = commune
                user_admin.set_password("pass")
                user_admin.save()
            self.stdout.write(f"Admin {user_admin.email} ready.")

            # Create agents
            agents = []
            for agent_email, fname in [(cdata["email_agent1"], "Agent 1"), (cdata["email_agent2"], "Agent 2")]:
                agent_user, created = User.objects.get_or_create(
                    email=agent_email,
                    defaults={
                        'first_name': fname,
                        'last_name': cdata["name"],
                        'role': 'agent',
                        'commune': commune,
                        'is_active': True,
                    }
                )
                if created:
                    agent_user.set_password("pass")
                    agent_user.save()
                else:
                    agent_user.role = 'agent'
                    agent_user.commune = commune
                    agent_user.set_password("pass")
                    agent_user.save()
                agents.append(agent_user)
                self.stdout.write(f"Agent {agent_user.email} ready.")

            # Create 5 citizens for this commune
            for i in range(5):
                phone = f"+22177{random.randint(1000000, 9999999)}"
                # Ensure phone is unique
                while Citoyen.objects.filter(telephone=phone).exists():
                    phone = f"+22177{random.randint(1000000, 9999999)}"
                
                cni = None
                if i % 2 == 0:
                    cni = f"1{random.randint(1000000000000, 9999999999999)}"

                citoyen = Citoyen.objects.create(
                    prenom=random.choice(prenoms),
                    nom=random.choice(noms),
                    date_naissance=date.today() - timedelta(days=random.randint(365*18, 365*60)),
                    sexe=random.choice(['M', 'F']),
                    telephone=phone,
                    commune=commune,
                    quartier=random.choice(quartiers),
                    numero_cni=cni,
                    nom_pere=f"{random.choice(prenoms)} {random.choice(noms)}",
                    nom_mere=f"{random.choice(prenoms)} {random.choice(noms)}",
                    created_by=user_supervisor
                )
                
                # Create 1 to 3 dossiers for this citizen
                num_dossiers = random.randint(1, 3)
                for j in range(num_dossiers):
                    status_choice = random.choice([Dossier.Status.DRAFT, Dossier.Status.SUBMITTED, Dossier.Status.IN_REVIEW, Dossier.Status.APPROVED, Dossier.Status.COMPLETED])
                    type_choice = random.choice([Dossier.Type.BIRTH_CERTIFICATE, Dossier.Type.DEATH_CERTIFICATE, Dossier.Type.MARRIAGE_CERTIFICATE, Dossier.Type.RESIDENCE_CERTIFICATE])
                    
                    Dossier.objects.create(
                        type=type_choice,
                        status=status_choice,
                        citoyen_guichet=citoyen,
                        commune=commune,
                        assigned_agent=random.choice(agents) if status_choice != Dossier.Status.DRAFT else None,
                        notes="Seed dossier",
                        submitted_at=timezone.now() if status_choice != Dossier.Status.DRAFT else None
                    )
            
            # Print stats
            citoyen_count = Citoyen.objects.filter(commune=commune).count()
            dossier_count = Dossier.objects.filter(commune=commune, citoyen_guichet__isnull=False).count()
            self.stdout.write(f"Commune {commune.name}: {citoyen_count} citoyens, {dossier_count} dossiers total.")

        # Create Super Admin (Global)
        super_admin, created = User.objects.get_or_create(
            email="superadmin@test.local",
            defaults={
                'first_name': 'Super',
                'last_name': 'Admin',
                'role': 'super_admin',
                'is_active': True,
                'is_superuser': True,
                'is_staff': True,
            }
        )
        if created:
            super_admin.set_password("pass")
            super_admin.save()
        else:
            super_admin.role = 'super_admin'
            super_admin.set_password("pass")
            super_admin.save()
        self.stdout.write(f"Super Admin {super_admin.email} ready.")

        # Reconnect signal
        post_save.connect(trigger_attribution_dossier, sender=Dossier)

        self.stdout.write(self.style.SUCCESS('Seed completed successfully!'))
