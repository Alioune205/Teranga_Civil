from django.apps import AppConfig

class EtatCivilConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.etat_civil'

    def ready(self):
        import apps.etat_civil.signals_attribution
