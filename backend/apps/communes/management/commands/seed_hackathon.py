"""
Management command to seed the database with communes, registre civil data,
and test users for the hackathon demo.
"""
from django.core.management.base import BaseCommand
from apps.communes.models import Commune
from apps.dossiers.models import RegistreCivil


COMMUNES_DATA = [
    {
        'name': 'Dakar Plateau',
        'region': 'Dakar',
        'department': 'Dakar',
        'code': 'DKR-PLT',
        'address': 'Place de l\'Indépendance, Dakar Plateau',
        'phone': '+221 33 821 00 00',
        'email': 'mairie@dakarplateau.sn',
    },
    {
        'name': 'Keur Massar',
        'region': 'Dakar',
        'department': 'Keur Massar',
        'code': 'DKR-KMS',
        'address': 'Avenue principale, Keur Massar',
        'phone': '+221 33 879 00 00',
        'email': 'mairie@keurmassar.sn',
    },
    {
        'name': 'Ndiaganiao',
        'region': 'Thiès',
        'department': 'Mbour',
        'code': 'THS-NDG',
        'address': 'Centre-ville, Ndiaganiao',
        'phone': '+221 33 957 00 00',
        'email': 'mairie@ndiaganiao.sn',
    },
]

# Données fictives du registre civil pour la démo
REGISTRE_DATA = [
    # === Dakar Plateau ===
    {
        'numero_registre': '2020-0142',
        'annee_registre': 2020,
        'commune_code': 'DKR-PLT',
        'type_acte': 'birth_certificate',
        'prenoms_enfant': 'Lansana',
        'nom_enfant': 'Coly',
        'sexe': 'Masculin',
        'heure_naissance': '08:30',
        'date_naissance_personne': '2000-05-15',
        'lieu_naissance': 'Dakar',
        'prenom_pere': 'Ousmane',
        'prenom_mere': 'Fatou',
        'nom_mere': 'Ndiaye',
    },
    {
        'numero_registre': '2019-0301',
        'annee_registre': 2019,
        'commune_code': 'DKR-PLT',
        'type_acte': 'birth_certificate',
        'prenoms_enfant': 'Aminata',
        'nom_enfant': 'Diallo',
        'sexe': 'Féminin',
        'heure_naissance': '14:15',
        'date_naissance_personne': '1995-03-22',
        'lieu_naissance': 'Dakar Plateau',
        'prenom_pere': 'Mamadou',
        'prenom_mere': 'Awa',
        'nom_mere': 'Sow',
    },
    {
        'numero_registre': '2021-0089',
        'annee_registre': 2021,
        'commune_code': 'DKR-PLT',
        'type_acte': 'marriage_certificate',
        'prenoms_enfant': 'Moussa',
        'nom_enfant': 'Ndiaye',
        'date_naissance_personne': '1988-11-10',
        'conjoint': 'Fatou Sow',
    },
    {
        'numero_registre': '2023-0015',
        'annee_registre': 2023,
        'commune_code': 'DKR-PLT',
        'type_acte': 'death_certificate',
        'prenoms_enfant': 'Ibrahima',
        'nom_enfant': 'Fall',
        'date_naissance_personne': '1950-01-01',
    },
    # === Keur Massar ===
    {
        'numero_registre': '2022-0567',
        'annee_registre': 2022,
        'commune_code': 'DKR-KMS',
        'type_acte': 'birth_certificate',
        'prenoms_enfant': 'Ousmane',
        'nom_enfant': 'Ba',
        'sexe': 'Masculin',
        'heure_naissance': '02:00',
        'date_naissance_personne': '2002-08-30',
        'lieu_naissance': 'Keur Massar',
        'prenom_pere': 'Amadou',
        'prenom_mere': 'Coumba',
        'nom_mere': 'Sy',
    },
    {
        'numero_registre': '2018-0233',
        'annee_registre': 2018,
        'commune_code': 'DKR-KMS',
        'type_acte': 'birth_certificate',
        'prenoms_enfant': 'Aissatou',
        'nom_enfant': 'Diop',
        'sexe': 'Féminin',
        'heure_naissance': '11:45',
        'date_naissance_personne': '1998-12-05',
        'lieu_naissance': 'Keur Massar',
        'prenom_pere': 'Cheikh',
        'prenom_mere': 'Marie',
        'nom_mere': 'Fall',
    },
    {
        'numero_registre': '2020-0078',
        'annee_registre': 2020,
        'commune_code': 'DKR-KMS',
        'type_acte': 'marriage_certificate',
        'prenoms_enfant': 'Abdoulaye',
        'nom_enfant': 'Sarr',
        'date_naissance_personne': '1990-06-18',
        'conjoint': 'Marième Gueye',
    },
    # === Ndiaganiao ===
    {
        'numero_registre': '2021-0045',
        'annee_registre': 2021,
        'commune_code': 'THS-NDG',
        'type_acte': 'birth_certificate',
        'prenoms_enfant': 'Modou',
        'nom_enfant': 'Faye',
        'sexe': 'Masculin',
        'heure_naissance': '06:20',
        'date_naissance_personne': '2001-04-12',
        'lieu_naissance': 'Ndiaganiao',
        'prenom_pere': 'Abdou',
        'prenom_mere': 'Ndeye',
        'nom_mere': 'Dieng',
    },
    {
        'numero_registre': '2019-0112',
        'annee_registre': 2019,
        'commune_code': 'THS-NDG',
        'type_acte': 'birth_certificate',
        'prenoms_enfant': 'Ndèye',
        'nom_enfant': 'Mbaye',
        'sexe': 'Féminin',
        'heure_naissance': '19:10',
        'date_naissance_personne': '1997-09-25',
        'lieu_naissance': 'Ndiaganiao',
        'prenom_pere': 'Ibrahima',
        'prenom_mere': 'Astou',
        'nom_mere': 'Seck',
    },
    {
        'numero_registre': '2023-0008',
        'annee_registre': 2023,
        'commune_code': 'THS-NDG',
        'type_acte': 'death_certificate',
        'prenoms_enfant': 'Cheikh',
        'nom_enfant': 'Dieng',
        'date_naissance_personne': '1945-02-14',
    },
]


class Command(BaseCommand):
    help = 'Seed the database with communes and registre civil data for hackathon demo'

    def handle(self, *args, **options):
        self.stdout.write(self.style.MIGRATE_HEADING('=== Seeding des Communes ==='))

        for data in COMMUNES_DATA:
            commune, created = Commune.objects.update_or_create(
                code=data['code'],
                defaults=data,
            )
            status = 'CRÉÉE' if created else 'MÀJ'
            self.stdout.write(f'  [{status}] {commune.name} ({commune.code})')

        self.stdout.write('')
        self.stdout.write(self.style.MIGRATE_HEADING('=== Seeding du Registre Civil ==='))

        for entry in REGISTRE_DATA:
            commune = Commune.objects.get(code=entry['commune_code'])
            registre, created = RegistreCivil.objects.update_or_create(
                numero_registre=entry['numero_registre'],
                annee_registre=entry['annee_registre'],
                commune=commune,
                type_acte=entry['type_acte'],
                defaults={
                    'prenoms_enfant': entry.get('prenoms_enfant', 'Inconnu'),
                    'nom_enfant': entry.get('nom_enfant', 'Inconnu'),
                    'sexe': entry.get('sexe', 'Masculin'),
                    'heure_naissance': entry.get('heure_naissance'),
                    'date_naissance_personne': entry['date_naissance_personne'],
                    'conjoint_nom_complet': entry.get('conjoint'),
                    'lieu_naissance': entry.get('lieu_naissance', 'Inconnu'),
                    'prenom_pere': entry.get('prenom_pere', 'Inconnu'),
                    'prenom_mere': entry.get('prenom_mere', 'Inconnue'),
                    'nom_mere': entry.get('nom_mere', 'Inconnue'),
                },
            )
            status = 'CRÉÉ' if created else 'MÀJ'
            self.stdout.write(
                f"  [{status}] {registre.numero_registre}/{registre.annee_registre} "
                f"— {registre.prenoms_enfant} {registre.nom_enfant} ({registre.get_type_acte_display()})"
            )

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(
            f'✅ {Commune.objects.count()} communes, '
            f'{RegistreCivil.objects.count()} registres civils en base.'
        ))
