from apps.users.models import User

users = User.objects.filter(is_active=True).values(
    'email', 'role', 'first_name', 'last_name', 'commune__name'
).order_by('role')[:20]

print("=" * 80)
print(f"{'ROLE':<30} {'EMAIL':<35} {'NOM':<25} {'COMMUNE'}")
print("=" * 80)
for u in users:
    nom = f"{u['first_name']} {u['last_name']}".strip()
    print(f"{u['role']:<30} {u['email']:<35} {nom:<25} {u['commune__name'] or '—'}")

# Réinitialiser les mdp de test
print("\n\nRéinitialisation des mots de passe de test à 'passer123'...")
citoyens = User.objects.filter(role='citizen', is_active=True)[:3]
for c in citoyens:
    c.set_password('passer123')
    c.save()
    print(f"  -> {c.email} → passer123")
