"""
Notifications models.
This application stores notification history and supports future push/email/SMS delivery.
"""
import uuid

from django.conf import settings
from django.db import models


class Notification(models.Model):
    """Notification envoyée à un utilisateur ou stockée pour usage interne."""

    class Type(models.TextChoices):
        INFO = 'info', 'Information'
        WARNING = 'warning', 'Alerte'
        ERROR = 'error', 'Erreur'
        UPDATE = 'update', 'Mise à jour'

    class Channel(models.TextChoices):
        INTERNAL = 'internal', 'Interne'
        EMAIL = 'email', 'Email'
        SMS = 'sms', 'SMS'
        PUSH = 'push', 'Push'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name='Utilisateur',
    )
    title = models.CharField(
        max_length=200,
        verbose_name='Titre',
    )
    message = models.TextField(
        verbose_name='Message',
    )
    notification_type = models.CharField(
        max_length=20,
        choices=Type.choices,
        default=Type.INFO,
        verbose_name='Type de notification',
    )
    channel = models.CharField(
        max_length=20,
        choices=Channel.choices,
        default=Channel.INTERNAL,
        verbose_name='Canal',
    )
    data = models.JSONField(
        blank=True,
        default=dict,
        verbose_name='Données associées',
        help_text='Métadonnées JSON utiles pour la notification.',
    )
    is_read = models.BooleanField(
        default=False,
        verbose_name='Lu',
    )
    delivered_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date de livraison',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de création',
    )

    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['is_read']),
        ]

    def __str__(self):
        return f'{self.title} → {self.user.email}'

    def mark_as_read(self):
        """Marque la notification comme lue."""
        self.is_read = True
        self.save(update_fields=['is_read'])


class DeviceToken(models.Model):
    """
    Stocke les tokens Firebase Cloud Messaging (FCM) associés à un utilisateur.
    Permet d'envoyer des notifications push ciblées sur un ou plusieurs appareils.
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='device_tokens',
        verbose_name='Utilisateur'
    )
    token = models.CharField(
        max_length=255,
        unique=True,
        verbose_name='FCM Token',
        db_index=True
    )
    device_type = models.CharField(
        max_length=50,
        blank=True,
        verbose_name="Type d'appareil"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de création',
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Dernière mise à jour',
    )

    class Meta:
        verbose_name = 'Device Token'
        verbose_name_plural = 'Device Tokens'
        indexes = [
            models.Index(fields=['user']),
        ]

    def __str__(self):
        return f"Token pour {self.user.email} ({self.device_type})"
