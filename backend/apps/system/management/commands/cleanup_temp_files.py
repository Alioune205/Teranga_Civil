import os
import time
import logging
from django.core.management.base import BaseCommand
from django.conf import settings

logger = logging.getLogger('system')

class Command(BaseCommand):
    help = 'Clean up temporary files older than a specified duration'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=1,
            help='Number of days after which a temporary file is considered stale (default: 1)',
        )

    def handle(self, *args, **options):
        days = options['days']
        self.stdout.write(f"Démarrage du nettoyage des fichiers temporaires (plus vieux que {days} jours)...")
        
        tmp_dir = os.path.join(settings.MEDIA_ROOT, 'tmp')
        
        if not os.path.exists(tmp_dir):
            self.stdout.write("Le dossier 'tmp' n'existe pas. Rien à nettoyer.")
            return

        now = time.time()
        threshold = days * 86400  # Convert days to seconds
        deleted_count = 0

        for filename in os.listdir(tmp_dir):
            file_path = os.path.join(tmp_dir, filename)
            if os.path.isfile(file_path):
                # Check file modification time
                if os.stat(file_path).st_mtime < now - threshold:
                    try:
                        os.remove(file_path)
                        deleted_count += 1
                        logger.info(f"Fichier temporaire supprimé : {filename}")
                    except Exception as e:
                        logger.error(f"Erreur lors de la suppression de {filename} : {e}")

        logger.info(f"Cleanup of temp files completed. Removed {deleted_count} files.")
        self.stdout.write(self.style.SUCCESS(f'Successfully deleted {deleted_count} temporary files.'))
