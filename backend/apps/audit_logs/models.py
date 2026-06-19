"""
AuditLog model for tracking all system actions.
"""
import uuid

from django.conf import settings
from django.db import models


class AuditLog(models.Model):
    """
    Immutable log entry for tracking user actions across the system.
    Created automatically via signals and utility functions.
    """

    class Action(models.TextChoices):
        CREATE = 'CREATE', 'Création'
        UPDATE = 'UPDATE', 'Modification'
        DELETE = 'DELETE', 'Suppression'
        LOGIN = 'LOGIN', 'Connexion'
        LOGOUT = 'LOGOUT', 'Déconnexion'
        STATUS_CHANGE = 'STATUS_CHANGE', 'Changement de statut'
        ROLE_CHANGE = 'ROLE_CHANGE', 'Changement de rôle'
        UPLOAD = 'UPLOAD', 'Téléversement'
        DOWNLOAD = 'DOWNLOAD', 'Téléchargement'
        ACCESS_DENIED = 'ACCESS_DENIED', 'Accès refusé'

    class UserType(models.TextChoices):
        USER = 'USER', 'Utilisateur'
        SYSTEM = 'SYSTEM', 'Système'
        ANONYMOUS = 'ANONYMOUS', 'Anonyme'

    class Status(models.TextChoices):
        SUCCESS = 'SUCCESS', 'Succès'
        FAILURE = 'FAILURE', 'Échec'
        ERROR = 'ERROR', 'Erreur'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs',
        verbose_name='Utilisateur',
    )
    user_type = models.CharField(
        max_length=20,
        choices=UserType.choices,
        default=UserType.USER,
        verbose_name='Type d\'utilisateur',
        db_index=True,
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.SUCCESS,
        verbose_name='Statut',
        db_index=True,
    )
    action = models.CharField(
        max_length=20,
        choices=Action.choices,
        verbose_name='Action',
        db_index=True,
    )
    resource_type = models.CharField(
        max_length=50,
        verbose_name='Type de ressource',
        db_index=True,
    )
    resource_id = models.UUIDField(
        null=True,
        blank=True,
        verbose_name='ID ressource',
    )
    details = models.JSONField(
        default=dict,
        blank=True,
        verbose_name='Détails',
    )
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        verbose_name='Adresse IP',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date',
        db_index=True,
    )

    class Meta:
        verbose_name = 'Log d\'audit'
        verbose_name_plural = 'Logs d\'audit'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'action']),
            models.Index(fields=['resource_type', 'resource_id']),
            models.Index(fields=['-created_at']),
        ]

    def __str__(self):
        user_str = self.user.email if self.user else 'Système'
        return f'[{self.action}] {user_str} — {self.resource_type} ({self.created_at})'

    @classmethod
    def log(cls, user=None, action='', resource_type='', resource_id=None, details=None, ip_address=None, user_type=None, status=None):
        """
        Convenience method to create an audit log entry.
        Usage: AuditLog.log(user=request.user, action='CREATE', resource_type='dossier', ...)
        """
        # Determine user_type if not explicitly provided
        if user_type is None:
            user_type = cls.UserType.USER if user else cls.UserType.ANONYMOUS

        if status is None:
            status = cls.Status.SUCCESS

        return cls.objects.create(
            user=user,
            user_type=user_type,
            action=action,
            status=status,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details or {},
            ip_address=ip_address,
        )
