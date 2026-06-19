import os
import time
import logging
from datetime import datetime
from django.core.management.base import BaseCommand
from django.conf import settings
from django.db import connection

logger = logging.getLogger('system')

class Command(BaseCommand):
    help = 'Crée une sauvegarde (dump) de la base de données'

    def handle(self, *args, **options):
        self.stdout.write("Démarrage de la sauvegarde de la base de données...")
        
        backup_dir = os.path.join(settings.BASE_DIR, 'media', 'backups')
        os.makedirs(backup_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Ce script simule une sauvegarde, car pg_dump nécessiterait d'être installé sur le serveur.
        # Dans un environnement de production réel avec PostgreSQL :
        # os.system(f"pg_dump -U {db_user} -h {db_host} {db_name} > {backup_path}")
        
        # Pour le mock, on crée un fichier de backup factice pour le Hackathon
        backup_filename = f"db_backup_{timestamp}.sql"
        backup_path = os.path.join(backup_dir, backup_filename)
        
        try:
            with open(backup_path, 'w') as f:
                f.write(f"-- SUNU CIVIL Database Backup\n")
                f.write(f"-- Generated on {datetime.now().isoformat()}\n")
                f.write(f"-- Vendor: PostgreSQL (Simulated)\n")
                # On pourrait dumper via dumpdata pour sqlite
                
            # Simulate backup delay
            time.sleep(1)
            
            logger.info(f"[Backup] Sauvegarde réussie : {backup_path}")
            self.stdout.write(self.style.SUCCESS(f'Backup réussi : {backup_filename}'))
            
            # Nettoyage des très vieux backups (garder les 7 derniers)
            backups = sorted([f for f in os.listdir(backup_dir) if f.startswith('db_backup_')])
            if len(backups) > 7:
                for old_backup in backups[:-7]:
                    os.remove(os.path.join(backup_dir, old_backup))
                    logger.info(f"[Backup] Ancien backup supprimé : {old_backup}")
                    
        except Exception as e:
            logger.error(f"[Backup] Échec de la sauvegarde : {str(e)}", exc_info=True)
            self.stdout.write(self.style.ERROR('Échec de la sauvegarde.'))
