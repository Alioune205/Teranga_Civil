from apps.etat_civil.services.moteur_scoring import MoteurScoring
from apps.etat_civil.models_attribution import ProfilAgent
from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import Dossier
import uuid

print("=== DEBUT TEST MOTEUR SCORING ===")

# Create a test agent if none exists
agent_user, created = User.objects.get_or_create(
    email="test_agent_scoring@terangacivil.sn",
    defaults={
        "first_name": "Agent",
        "last_name": "Test",
        "phone": "771234567",
        "role": "officier",
        "is_active": True
    }
)

if created:
    agent_user.set_password("password123")
    agent_user.save()

profil, p_created = ProfilAgent.objects.get_or_create(
    user=agent_user,
    defaults={
        "capacite_maximale": 5,
        "score_performance_global": 80,
        "statut_actuel": ProfilAgent.Status.EN_LIGNE
    }
)

commune, _ = Commune.objects.get_or_create(name="Dakar Plateau", defaults={"code": "DKR-PLAT"})

# Setup user commune to match
agent_user.commune = commune
agent_user.save()

# Setup a test dossier
test_user, _ = User.objects.get_or_create(email="citizen@test.com", defaults={"role": "citoyen", "first_name": "Citizen", "last_name": "Test"})
dossier, _ = Dossier.objects.get_or_create(
    reference=f"NAISS-TEST-{uuid.uuid4().hex[:4]}",
    defaults={
        "citoyen": test_user,
        "commune": commune,
        "type": "birth_certificate",
        "status": "pending"
    }
)

score = MoteurScoring.evaluer_agent_pour_dossier(profil, dossier)

print(f"Agent: {agent_user.email}")
print(f"Charge actuelle: {profil.charge_actuelle} / {profil.capacite_maximale}")
print(f"Score performance de base: {profil.score_performance_global}")
print(f"Score calculé final par le moteur: {score}")

best_agent, best_score = MoteurScoring.trouver_meilleur_agent(dossier)
print(f"Trouver meilleur agent - Agent: {best_agent.user.email if best_agent else 'Aucun'} - Score: {best_score}")

print("=== FIN TEST MOTEUR SCORING ===")
