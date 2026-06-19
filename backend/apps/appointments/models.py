from django.db import models
from django.conf import settings
from apps.shared.models import TimeStampedModel

class Appointment(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = 'pending', 'En attente'
        SCHEDULED = 'scheduled', 'Programmé'
        COMPLETED = 'completed', 'Terminé'
        CANCELLED = 'cancelled', 'Annulé'

    dossier = models.ForeignKey(
        'dossiers.Dossier',
        on_delete=models.CASCADE,
        related_name='appointments',
        verbose_name='Dossier'
    )
    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='appointments',
        verbose_name='Citoyen'
    )
    agent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_appointments',
        verbose_name='Agent responsable'
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name='Statut'
    )
    scheduled_date = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date et heure du rendez-vous'
    )
    reason = models.TextField(
        blank=True,
        default='',
        verbose_name='Motif'
    )

    class Meta:
        verbose_name = 'Rendez-vous'
        verbose_name_plural = 'Rendez-vous'
        ordering = ['-created_at']

    def __str__(self):
        return f'RDV pour {self.dossier.reference} - {self.get_status_display()}'
