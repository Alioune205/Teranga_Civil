import uuid
from django.utils import timezone
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.communes.models import Commune
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier

print("=== SIMULATION D'UNE NOUVELLE DEMANDE DE DOSSIER ===")

# S'assurer qu'il y a un agent en ligne
agent_user = User.objects.filter(role="officier").first()
if agent_user:
    profil = ProfilAgent.objects.filter(user=agent_user).first()
    if profil:
        profil.statut_actuel = ProfilAgent.Status.EN_LIGNE
        profil.save()

# Création d'un dossier avec status SUBMITTED
commune = Commune.objects.first()
applicant = User.objects.filter(role="citoyen").first()

if not applicant:
    print("Création d'un citoyen temporaire...")
    applicant = User.objects.create(email=f"citoyen_{uuid.uuid4().hex[:4]}@test.com", role="citoyen")

print("Création du dossier (status=SUBMITTED)...")
dossier = Dossier.objects.create(
    reference=f"NAISS-SIMUL-{uuid.uuid4().hex[:4]}",
    citoyen=applicant,
    commune=commune,
    type="birth_certificate",
    status="submitted"  # Dossier.Status.SUBMITTED
)

print(f"Dossier {dossier.reference} créé avec succès.")

# Note: task_attribuer_dossier_async.delay(instance.id) is called in the signal.
# Wait a second to check if the attribution was created (if Celery runs in eager mode).
from django.conf import settings
if getattr(settings, 'CELERY_TASK_ALWAYS_EAGER', False):
    print("Celery est en mode EAGER, vérification de l'attribution...")
    attribution = AttributionDossier.objects.filter(dossier=dossier).first()
    if attribution:
        print(f"SUCCÈS: Attribution asynchrone créée -> Agent: {attribution.agent.user.email}, Score: {attribution.score_matching_initial}")
    else:
        print("ÉCHEC: Aucune attribution trouvée.")
else:
    print("Le dossier a été sauvegardé. La tâche Celery a été envoyée (Mode Asynchrone).")

print("=== FIN DE LA SIMULATION ===")
