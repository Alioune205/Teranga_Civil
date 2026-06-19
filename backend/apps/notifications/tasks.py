"""
Notifications tasks — Tâches automatisées pour les notifications.

Peut être exécuté via :
    - Management commands : python manage.py send_stale_alerts
    - Celery Beat : configuration dans settings.py
    - Cron job : appel direct des fonctions

Chaque tâche est idempotente et loggée pour le monitoring.
"""
import logging
from datetime import timedelta

from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models import Q

from apps.dossiers.models import Dossier
from .services import FCMService
from .models import Notification

logger = logging.getLogger('system')
User = get_user_model()


def send_stale_dossier_alerts(stale_hours=48):
    """
    Envoie des alertes aux agents pour les dossiers en attente depuis trop longtemps.
    À appeler périodiquement (cron ou Celery beat).

    Optimisations :
        - `select_related` pour éviter les N+1 queries
        - Dédoublonnage par agent (un seul message par agent)
        - Notification groupée avec le nombre total de dossiers bloqués

    Args:
        stale_hours: Nombre d'heures sans action avant alerte (défaut: 48).

    Returns:
        int: Nombre d'agents notifiés.
    """
    threshold = timezone.now() - timedelta(hours=stale_hours)

    stale_dossiers = Dossier.objects.filter(
        status__in=[Dossier.Status.SUBMITTED, Dossier.Status.IN_REVIEW],
        submitted_at__lte=threshold,
    ).select_related('assigned_agent', 'citizen', 'commune')

    count = stale_dossiers.count()
    if count == 0:
        logger.info('[Tasks] Aucun dossier en attente dépassant le seuil.')
        return 0

    logger.info(f'[Tasks] {count} dossier(s) en attente depuis plus de {stale_hours}h.')

    # Regrouper les dossiers par agent pour éviter le spam
    agent_dossiers = {}
    for dossier in stale_dossiers:
        if dossier.assigned_agent:
            agent_id = dossier.assigned_agent.id
            if agent_id not in agent_dossiers:
                agent_dossiers[agent_id] = {
                    'agent': dossier.assigned_agent,
                    'dossiers': [],
                }
            agent_dossiers[agent_id]['dossiers'].append(dossier)

    # Envoyer un résumé par agent (pas un message par dossier)
    for agent_id, info in agent_dossiers.items():
        agent = info['agent']
        dossier_count = len(info['dossiers'])
        references = ', '.join(d.reference for d in info['dossiers'][:5])
        suffix = f' et {dossier_count - 5} autre(s)' if dossier_count > 5 else ''

        FCMService.send_notification_to_user(
            user=agent,
            title=f'⚠️ {dossier_count} dossier(s) urgent(s)',
            body=(
                f'{dossier_count} dossier(s) en attente depuis plus de {stale_hours}h : '
                f'{references}{suffix}.'
            ),
            notification_type=Notification.TypeChoices.ALERT,
            data={
                'action': 'stale_alert',
                'count': dossier_count,
            },
        )

    logger.info(f'[Tasks] Alertes envoyées à {len(agent_dossiers)} agent(s).')
    return len(agent_dossiers)


def send_daily_summary_to_admins():
    """
    Envoie un résumé quotidien aux administrateurs :
    nombre de dossiers reçus, traités, en attente.

    Returns:
        int: Nombre d'administrateurs notifiés.
    """
    now = timezone.now()
    yesterday = now - timedelta(days=1)

    received = Dossier.objects.filter(submitted_at__gte=yesterday).count()
    completed = Dossier.objects.filter(completed_at__gte=yesterday).count()
    pending = Dossier.objects.filter(
        status__in=[Dossier.Status.SUBMITTED, Dossier.Status.IN_REVIEW]
    ).count()

    admins = User.objects.filter(
        role__in=['civil_admin', 'super_admin'],
        is_active=True,
    )

    admin_count = admins.count()
    if admin_count == 0:
        logger.info('[Tasks] Aucun administrateur actif trouvé.')
        return 0

    # Utiliser bulk notification au lieu d'une boucle
    count = FCMService.send_bulk_notification(
        users=admins,
        title='📊 Résumé quotidien',
        body=(
            f'Dernières 24h : {received} dossier(s) reçu(s), '
            f'{completed} traité(s). '
            f'{pending} dossier(s) en attente au total.'
        ),
        notification_type=Notification.TypeChoices.INFO,
        data={'action': 'daily_summary'},
    )

    logger.info(f'[Tasks] Résumé quotidien envoyé à {count} administrateur(s).')
    return count


def cleanup_old_notifications(days=90):
    """
    Supprime les notifications lues de plus de N jours.
    Évite l'accumulation en base de données.

    Args:
        days: Nombre de jours après lesquels supprimer (défaut: 90).

    Returns:
        int: Nombre de notifications supprimées.
    """
    threshold = timezone.now() - timedelta(days=days)
    deleted, _ = Notification.objects.filter(
        is_read=True,
        created_at__lte=threshold,
    ).delete()

    logger.info(f'[Tasks] {deleted} notification(s) lue(s) de plus de {days} jours supprimée(s).')
    return deleted


def notify_citizen_dossier_reminder():
    """
    Rappelle aux citoyens que leur dossier en brouillon n'a pas été soumis.
    Cible les dossiers en brouillon créés il y a plus de 3 jours.

    Optimisation : évite les doublons (ne rappelle pas si un rappel a déjà
    été envoyé dans les dernières 24h).

    Returns:
        int: Nombre de citoyens notifiés.
    """
    threshold = timezone.now() - timedelta(days=3)
    recent_reminder_threshold = timezone.now() - timedelta(hours=24)

    draft_dossiers = Dossier.objects.filter(
        status=Dossier.Status.DRAFT,
        created_at__lte=threshold,
    ).select_related('citizen')

    notified = 0
    already_reminded = set()

    for dossier in draft_dossiers:
        citizen = dossier.citizen

        # Éviter les doublons : un rappel par citoyen max
        if citizen.id in already_reminded:
            continue

        # Vérifier qu'on n'a pas déjà envoyé un rappel récemment
        recent_reminder = Notification.objects.filter(
            user=citizen,
            data__action='draft_reminder',
            created_at__gte=recent_reminder_threshold,
        ).exists()

        if recent_reminder:
            continue

        FCMService.send_notification_to_user(
            user=citizen,
            title='📝 Rappel : dossier non soumis',
            body=(
                f'Votre dossier {dossier.reference} est toujours en brouillon. '
                f'N\'oubliez pas de le soumettre pour qu\'il soit traité.'
            ),
            notification_type=Notification.TypeChoices.INFO,
            data={
                'dossier_id': str(dossier.id),
                'action': 'draft_reminder',
            },
        )
        already_reminded.add(citizen.id)
        notified += 1

    logger.info(f'[Tasks] Rappels envoyés à {notified} citoyen(s) pour dossiers en brouillon.')
    return notified
