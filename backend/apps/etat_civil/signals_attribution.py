import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.dossiers.models import Dossier
from apps.etat_civil.tasks_attribution import attribuer_dossier_async

logger = logging.getLogger('apps')

@receiver(post_save, sender=Dossier)
def trigger_attribution_dossier(sender, instance, created, **kwargs):
    logger.info(f"Signal post_save Dossier activé pour dossier {instance.id} (created={created}, status={instance.status})")
    if instance.status in ['soumis', 'submitted', Dossier.Status.SUBMITTED] and not instance.assigned_agent:
        logger.info(f"Déclenchement de l'attribution pour le dossier {instance.id}")
        # En mode développement on exécute directement sans .delay si pas de worker Celery
        try:
            attribuer_dossier_async.delay(instance.id)
        except Exception:
            attribuer_dossier_async(instance.id)

