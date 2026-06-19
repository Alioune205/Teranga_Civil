from apps.users.models import User
from django.apps import apps

# Chercher le modèle profil citoyen
try:
    CitoyenProfile = apps.get_model('etat_civil', 'Citoyen')
    citoyens = CitoyenProfile.objects.select_related('user').all()[:10]
    print(f"Modèle: etat_civil.Citoyen — {citoyens.count()} trouvés")
    for c in citoyens:
        print(vars(c))
except Exception as e:
    print(f"etat_civil.Citoyen: {e}")

# Essayer le modèle authentication
try:
    CitoyenProfile2 = apps.get_model('authentication', 'CitoyenProfile')
    print(f"\nModèle: authentication.CitoyenProfile")
    items = CitoyenProfile2.objects.all()[:5]
    for i in items:
        print(vars(i))
except Exception as e:
    print(f"authentication.CitoyenProfile: {e}")

# Chercher dans tous les modèles
print("\n--- Tous les modèles disponibles avec 'citoyen' ou 'profile' ---")
for model in apps.get_models():
    name = model.__name__.lower()
    if any(x in name for x in ['citoyen', 'profile', 'citizen', 'registre', 'birth']):
        fields = [f.name for f in model._meta.get_fields()]
        print(f"{model._meta.app_label}.{model.__name__}: {fields[:15]}")
