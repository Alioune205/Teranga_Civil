import os
from celery import Celery

# Définir le module de paramètres par défaut pour 'celery'.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')

app = Celery('config')

# Utiliser une chaîne de caractères pour que le worker n'ait pas à sérialiser
# l'objet de configuration. namespace='CELERY' signifie que toutes les clés de
# configuration liées à Celery doivent avoir le préfixe `CELERY_`.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Charger les tâches depuis toutes les applications Django enregistrées.
app.autodiscover_tasks()

@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
