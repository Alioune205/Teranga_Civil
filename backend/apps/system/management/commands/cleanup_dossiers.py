import logging
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.dossiers.models import Dossier

logger = logging.getLogger('system')

class Command(BaseCommand):
    help = 'Clean up stale or temporary DRAFT dossiers older than 30 days'

    def handle(self, *args, **kwargs):
        self.stdout.write("Démarrage du nettoyage des dossiers obsolètes...")
        logger.info(f"Running dossier cleanup at {timezone.now()}")
        
        # Supprimer les dossiers en statut DRAFT créés il y a plus de 30 jours
        threshold = timezone.now() - timedelta(days=30)
        stale_dossiers = Dossier.objects.filter(
            status=Dossier.Status.DRAFT,
            created_at__lte=threshold
        )
        
        count = stale_dossiers.count()
        if count > 0:
            stale_dossiers.delete()
            
        logger.info(f"Cleanup completed. Removed {count} stale DRAFT dossiers.")
        self.stdout.write(self.style.SUCCESS(f'Successfully cleaned up {count} DRAFT dossiers.'))
