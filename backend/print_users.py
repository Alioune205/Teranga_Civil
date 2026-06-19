import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

print("CITOYENS :")
for u in User.objects.filter(role='citizen')[:10]:
    print(f"- {u.email or getattr(u, 'phone_number', u.username)} : {u.first_name} {u.last_name} (Mot de passe: passpass)")

print("\nAGENTS :")
for u in User.objects.filter(role__in=['civil_admin', 'super_admin'])[:5]:
    print(f"- {u.email or getattr(u, 'phone_number', u.username)} : {u.first_name} {u.last_name} (Rôle: {u.role})")
