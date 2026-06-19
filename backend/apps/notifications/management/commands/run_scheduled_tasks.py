import logging
from django.core.management.base import BaseCommand
from apps.notifications.tasks import (
    send_stale_dossier_alerts,
    send_daily_summary_to_admins,
    cleanup_old_notifications,
    notify_citizen_dossier_reminder
)

logger = logging.getLogger('system')

class Command(BaseCommand):
    help = 'Run all scheduled automated tasks (reminders, cleanup, alerts).'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Début de l'exécution des tâches planifiées..."))
        
        try:
            # 1. Alertes d'agents pour les dossiers en attente (>48h)
            agents_alerted = send_stale_dossier_alerts()
            self.stdout.write(f"- Alertes de dossiers en attente: {agents_alerted} agents notifiés.")
            
            # 2. Résumé quotidien aux admins
            admins_alerted = send_daily_summary_to_admins()
            self.stdout.write(f"- Résumés quotidiens: {admins_alerted} administrateurs notifiés.")
            
            # 3. Rappels aux citoyens pour les brouillons
            citizens_reminded = notify_citizen_dossier_reminder()
            self.stdout.write(f"- Rappels de brouillons: {citizens_reminded} citoyens notifiés.")
            
            # 4. Nettoyage des anciennes notifications (>90j)
            cleaned = cleanup_old_notifications()
            self.stdout.write(f"- Nettoyage: {cleaned} anciennes notifications supprimées.")
            
            self.stdout.write(self.style.SUCCESS("Toutes les tâches ont été exécutées avec succès."))
        except Exception as e:
            logger.error(f"Erreur lors de l'exécution des tâches planifiées : {str(e)}", exc_info=True)
            self.stdout.write(self.style.ERROR(f"Une erreur est survenue : {str(e)}"))
