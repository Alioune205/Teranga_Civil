import os
import django
import random
from datetime import timedelta
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.users.models import User
from apps.dossiers.models import Dossier
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier, JournalAttribution
from apps.communes.models import Commune

def clean_old_data():
    print("Nettoyage des anciennes données d'attribution...")
    JournalAttribution.objects.all().delete()
    AttributionDossier.objects.all().delete()
    
    try:
        # On supprime seulement les dossiers de test pour ne pas casser la base
        Dossier.objects.filter(citizen__email="citoyen_masse@test.sn").delete()
        
        # On supprime les agents de test
        User.objects.filter(email__contains="agent_mass").delete()
    except Exception as e:
        print(f"Ignored clean error: {e}")

def seed_massive():
    print("=== Début du Seeding Massif ===")
    
    commune = Commune.objects.first()
    if not commune:
        print("Erreur: Aucune commune existante. Veuillez créer une commune d'abord.")
        return

    # 1. Création d'un citoyen générique
    citoyen, _ = User.objects.get_or_create(
        email="citoyen_masse@test.sn",
        defaults={"first_name": "Citoyen", "last_name": "Masse", "role": "citizen"}
    )

    # 2. Création de 8 Agents aux profils variés
    print("Création de 8 Agents...")
    noms_agents = [
        ("Moussa", "Diop", ["naissance", "mariage"], 15, 85, 90, 20),
        ("Fatoumata", "Sow", ["deces", "residence"], 10, 95, 80, 15),
        ("Cheikh", "Ndiaye", ["legalisation"], 20, 70, 60, 40),
        ("Aminata", "Ba", ["naissance", "deces"], 12, 88, 85, 25),
        ("Ibrahima", "Faye", ["mariage", "legalisation", "juridique"], 8, 98, 95, 10),
        ("Khadija", "Fall", ["naissance", "residence"], 18, 75, 70, 35),
        ("Ousmane", "Sy", ["deces", "legalisation"], 14, 82, 88, 22),
        ("Awa", "Gueye", ["juridique", "mariage"], 10, 92, 92, 18),
    ]

    agents_crees = []
    for i, (prenom, nom, specialites, charge, reussite, delais, temps) in enumerate(noms_agents):
        user, _ = User.objects.get_or_create(
            email=f"agent_mass_{i}@terangacivil.sn",
            defaults={"first_name": prenom, "last_name": nom, "role": "agent", "is_active": True}
        )
        user.set_password("Passer123!")
        user.save()
        
        ProfilAgent.objects.get_or_create(
            user=user,
            defaults={
                "specialites": specialites,
                "charge_maximale": charge,
                "taux_reussite": reussite,
                "taux_respect_delais": delais,
                "temps_moyen_traitement": temps
            }
        )
        agents_crees.append(user)

    # 3. Création Massive de Dossiers
    print("Création de 50 Dossiers...")
    types = ['extrait_naissance', 'mariage', 'deces', 'residence', 'legalisation']
    
    dossiers_attente = []
    dossiers_traitement = []
    dossiers_termines = []
    dossiers_rejetes = []

    now = timezone.now()

    # 10 en attente (status='soumis')
    for _ in range(10):
        d = Dossier.objects.create(type=random.choice(types), status=Dossier.Status.SUBMITTED, citizen=citoyen, commune=commune)
        d.created_at = now - timedelta(hours=random.randint(1, 48))
        d.save()
        dossiers_attente.append(d)

    # 25 en traitement (status='in_review' ou 'generated')
    for _ in range(25):
        d = Dossier.objects.create(type=random.choice(types), status=random.choice([Dossier.Status.IN_REVIEW, Dossier.Status.APPROVED]), citizen=citoyen, commune=commune)
        d.created_at = now - timedelta(days=random.randint(1, 5))
        d.save()
        dossiers_traitement.append(d)

    # 10 terminés (status='delivered')
    for _ in range(10):
        d = Dossier.objects.create(type=random.choice(types), status=Dossier.Status.COMPLETED, citizen=citoyen, commune=commune)
        d.created_at = now - timedelta(days=random.randint(5, 15))
        d.completed_at = d.created_at + timedelta(days=random.randint(1, 4))
        d.save()
        dossiers_termines.append(d)

    # 5 rejetés (status='rejected')
    for _ in range(5):
        d = Dossier.objects.create(type=random.choice(types), status=Dossier.Status.REJECTED, citizen=citoyen, commune=commune)
        d.created_at = now - timedelta(days=random.randint(2, 10))
        d.rejection_reason = "Documents illisibles ou manquants."
        d.save()
        dossiers_rejetes.append(d)

    # 4. Attributions Manuelles pour peupler le tableau de bord
    print("Assignation des dossiers aux agents...")
    for d in dossiers_traitement:
        agent = random.choice(agents_crees)
        score = random.uniform(60.0, 99.9)
        priorite = random.choice(['normal', 'eleve', 'urgent'])
        
        # Lier le dossier à l'agent
        d.assigned_agent = agent
        d.save()

        AttributionDossier.objects.create(
            dossier=d,
            agent_actuel=agent,
            score_attribution=score,
            niveau_priorite=priorite,
            justification_ia=f"Assignation automatique optimale. Compétence reconnue sur {d.type} avec un score de {score:.1f}%.",
            date_attribution=now - timedelta(hours=random.randint(1, 72)),
            date_limite_traitement=now + timedelta(days=2)
        )

        # Journal IA
        JournalAttribution.objects.create(
            dossier_id=d.id,
            libelle_action="Attribution initiale (IA)",
            agent_apres=agent.email,
            score_calcule=score,
            justification="Meilleur profil identifié par le moteur de scoring.",
            responsable=None
        )

    # 5. Simulation de quelques interventions "Superviseur"
    print("Génération de l'historique Superviseur...")
    for _ in range(4):
        d = random.choice(dossiers_traitement)
        attr = AttributionDossier.objects.filter(dossier=d).first()
        if attr:
            ancien_agent = attr.agent_actuel
            nouveau_agent = random.choice([a for a in agents_crees if a != ancien_agent])
            
            attr.agent_actuel = nouveau_agent
            attr.save()
            d.assigned_agent = nouveau_agent
            d.save()

            JournalAttribution.objects.create(
                dossier_id=d.id,
                libelle_action="Réattribution (Superviseur)",
                agent_avant=ancien_agent.email,
                agent_apres=nouveau_agent.email,
                score_calcule=0,
                justification=random.choice([
                    "Surcharge de l'agent précédent", 
                    "Dossier urgent nécessitant un expert", 
                    "Absence imprévue de l'agent"
                ]),
                responsable=User.objects.filter(email="admin@terangacivil.sn").first()
            )

    print("\n=== Seeding Massif Terminé avec Succès ! ===")
    print(f"Total: {len(agents_crees)} Agents, {len(dossiers_attente)+len(dossiers_traitement)+len(dossiers_termines)+len(dossiers_rejetes)} Dossiers créés.")

if __name__ == '__main__':
    clean_old_data()
    seed_massive()
