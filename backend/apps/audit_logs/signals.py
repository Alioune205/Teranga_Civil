from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.conf import settings
from .models import AuditLog

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def log_user_save(sender, instance, created, **kwargs):
    action = AuditLog.Action.CREATE if created else AuditLog.Action.UPDATE
    AuditLog.log(
        user=None, # L'acteur exact n'est pas dispo dans le signal sans thread-local
        action=action,
        resource_type='user',
        resource_id=instance.id,
        details={'email': instance.email, 'source': 'signal_post_save'}
    )

@receiver(post_delete, sender=settings.AUTH_USER_MODEL)
def log_user_delete(sender, instance, **kwargs):
    AuditLog.log(
        user=None,
        action=AuditLog.Action.DELETE,
        resource_type='user',
        resource_id=instance.id,
        details={'email': instance.email, 'source': 'signal_post_delete'}
    )

# Suivi du modèle Dossier
@receiver(post_save, sender='dossiers.Dossier')
def log_dossier_save(sender, instance, created, **kwargs):
    action = AuditLog.Action.CREATE if created else AuditLog.Action.STATUS_CHANGE
    AuditLog.log(
        user=None,
        action=action,
        resource_type='dossier',
        resource_id=instance.id,
        details={
            'reference': getattr(instance, 'reference', 'unknown'),
            'status': getattr(instance, 'status', 'unknown'),
            'source': 'signal_post_save'
        }
    )

@receiver(post_delete, sender='dossiers.Dossier')
def log_dossier_delete(sender, instance, **kwargs):
    AuditLog.log(
        user=None,
        action=AuditLog.Action.DELETE,
        resource_type='dossier',
        resource_id=instance.id,
        details={
            'reference': getattr(instance, 'reference', 'unknown'),
            'source': 'signal_post_delete'
        }
    )
