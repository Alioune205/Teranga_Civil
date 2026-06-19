from apps.users.models import User
from django.apps import apps

CitizenProfile = apps.get_model('users', 'CitizenProfile')
RegistreCivil = apps.get_model('dossiers', 'RegistreCivil')
Citoyen = apps.get_model('etat_civil', 'Citoyen')

print("=" * 90)
print("COMPTES CITOYENS AVEC PROFIL (CitizenProfile)")
print("=" * 90)
profiles = CitizenProfile.objects.select_related('user').all()[:10]
for p in profiles:
    u = p.user
    print(f"Email       : {u.email}")
    print(f"Mot de passe: passer123")
    print(f"Nom         : {u.first_name} {u.last_name}")
    print(f"Date naissan: {p.date_of_birth}")
    print(f"CNI         : {p.cni_number or '—'}")
    print(f"Lieu naissan: {p.place_of_birth or '—'}")
    print("-" * 60)

print("\n")
print("=" * 90)
print("REGISTRES CIVILS (numéro & année de registre)")
print("=" * 90)
registres = RegistreCivil.objects.select_related('commune').all()[:10]
for r in registres:
    print(f"N° Registre : {r.numero_registre}  |  Année : {r.annee_registre}  |  Type : {r.type_acte}")
    print(f"Personne    : {r.nom_complet_personne}  |  Naissance : {r.date_naissance_personne}")
    print(f"Commune     : {r.commune.name if r.commune else '—'}")
    print("-" * 60)

print("\n")
print("=" * 90)
print("CITOYENS etat_civil (profils sans compte utilisateur)")
print("=" * 90)
citoyens = Citoyen.objects.all()[:10]
for c in citoyens:
    print(f"Nom         : {c.prenom} {c.nom}")
    print(f"Naissance   : {c.date_naissance}  |  Lieu : {c.lieu_naissance}")
    print(f"Téléphone   : {c.telephone or '—'}  |  Email : {c.email or '—'}")
    print(f"Père        : {c.nom_pere or '—'}  |  Mère : {c.nom_mere or '—'}")
    print("-" * 60)
