import logging
from django.core.management.base import BaseCommand
from django.core.management import call_command
from apps.notifications.tasks import (
    send_stale_dossier_alerts,
    send_daily_summary_to_admins,
    cleanup_old_notifications,
    notify_citizen_dossier_reminder
)

logger = logging.getLogger('system')

class Command(BaseCommand):
    help = 'Run all periodic automated system tasks (notifications, reminders, cleanup)'

    def handle(self, *args, **kwargs):
        self.stdout.write("Démarrage des tâches planifiées...")
        logger.info("Démarrage des tâches planifiées système.")

        # 1. Rappel aux citoyens pour dossiers en brouillon
        notified_citizens = notify_citizen_dossier_reminder()
        self.stdout.write(f"- Rappels brouillon envoyés: {notified_citizens}")

        # 2. Alerte aux agents pour les dossiers en attente depuis longtemps
        alerted_agents = send_stale_dossier_alerts(stale_hours=48)
        self.stdout.write(f"- Alertes de retard envoyées aux agents: {alerted_agents}")

        # 3. Résumé quotidien pour les administrateurs
        notified_admins = send_daily_summary_to_admins()
        self.stdout.write(f"- Résumés quotidiens envoyés aux admins: {notified_admins}")

        # 4. Nettoyage des anciennes notifications lues
        deleted_notifications = cleanup_old_notifications(days=90)
        self.stdout.write(f"- Anciennes notifications supprimées: {deleted_notifications}")

        # 5. Nettoyage des fichiers temporaires
        self.stdout.write("- Lancement du nettoyage des fichiers temporaires...")
        call_command('cleanup_temp_files')

        # 6. Sauvegarde automatique de la base de données
        self.stdout.write("- Lancement de la sauvegarde de la base de données...")
        call_command('backup_db')

        logger.info("Fin de l'exécution des tâches planifiées système.")
        self.stdout.write(self.style.SUCCESS("Toutes les tâches planifiées ont été exécutées avec succès."))
