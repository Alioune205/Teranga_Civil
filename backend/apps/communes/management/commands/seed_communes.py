from django.core.management.base import BaseCommand
from apps.communes.models import Commune

class Command(BaseCommand):
    help = 'Seed the communes for Teranga Civil'

    def handle(self, *args, **kwargs):
        communes_data = [
            {
                "code": "DKR-PLT",
                "name": "Dakar Plateau",
                "nom_commune_officiel": "Commune de Dakar Plateau",
                "region": "Dakar",
                "department": "Dakar",
                "devise": "Un Peuple - Un But - Une Foi",
                "nom_officier_etat_civil": "El hadji Idrissa Ndiaye",
                "chemin_cachet_communal": "assets/seals/dakar_plateau/Cachet_Communal_Commune_De_Dakar_Plateau.png",
                "chemin_cachet_nominal": "assets/seals/dakar_plateau/Cachet_Nominal_Officier_Etat_Civil_El_hadji_Idrissa_Ndiaye_Dakar_Plateau.png",
                "chemin_signature_officier": "assets/seals/dakar_plateau/Signarure_Officier_Etat_Civil_El_hadji_Idrissa_Ndiaye_Dakar_Plateau.png",
                "prefixe_residence": "RES-2026-",
                "prefixe_mariage": "MAR-2026-",
                "prefixe_deces": "DEC-2026-",
            },
            {
                "code": "DKR-KMS",
                "name": "Keur Massar",
                "nom_commune_officiel": "Commune de Keur Massar",
                "region": "Dakar",
                "department": "Keur Massar",
                "devise": "Un Peuple - Un But - Une Foi",
                "nom_officier_etat_civil": "Khadija Faye",
                "chemin_cachet_communal": "assets/seals/keur_massar/Cachet_Communal_Commune_De_Keur_Massar.png",
                "chemin_cachet_nominal": "assets/seals/keur_massar/Cachet_Nominal_Officier_Etat_Civil_Khadija_Faye_Keur_Massar.png",
                "chemin_signature_officier": "assets/seals/keur_massar/Signarure_Officier_Etat_Civil_Khadija_Faye_Keur_Massar.png",
                "prefixe_residence": "RES-2026-",
                "prefixe_mariage": "MAR-2026-",
                "prefixe_deces": "DEC-2026-",
            },
            {
                "code": "THI-NDG",
                "name": "Ndiaganiao",
                "nom_commune_officiel": "Commune de Ndiaganiao",
                "region": "Thiès",
                "department": "Mbour",
                "devise": "Un Peuple - Un But - Une Foi",
                "nom_officier_etat_civil": "Sidi Pouye",
                "chemin_cachet_communal": "assets/seals/ndiaganiao/Cachet_Communal_Commune_De_Ndiaganiao.png",
                "chemin_cachet_nominal": "assets/seals/ndiaganiao/Cachet_Nominal_Officier_Etat_Civil_Sidi_Pouye_Ndiaganiao.png",
                "chemin_signature_officier": "assets/seals/ndiaganiao/Signarure_Officier_Etat_Civil_Sidi_Pouye_Ndiaganiao.png",
                "prefixe_residence": "RES-2026-",
                "prefixe_mariage": "MAR-2026-",
                "prefixe_deces": "DEC-2026-",
            }
        ]

        for data in communes_data:
            commune, created = Commune.objects.update_or_create(
                code=data["code"],
                defaults=data
            )
            action = "Créée" if created else "Mise à jour"
            self.stdout.write(self.style.SUCCESS(f"{action} : {commune.nom_commune_officiel}"))
            
        self.stdout.write(self.style.SUCCESS('Toutes les communes ont été initialisées avec succès !'))
