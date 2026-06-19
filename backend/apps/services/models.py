"""
Services models — Paiements, Signalements citoyens, Sondages.
"""
import uuid
from django.conf import settings
from django.db import models
from apps.shared.models import TimeStampedModel


# =============================================================================
# PAIEMENTS
# =============================================================================

class Transaction(TimeStampedModel):
    """
    Transaction de paiement mobile (Wave, Orange Money, Free Money).
    Liée à un dossier et un citoyen.
    """

    class Provider(models.TextChoices):
        WAVE = 'wave', 'Wave'
        ORANGE_MONEY = 'orange_money', 'Orange Money'
        FREE_MONEY = 'free_money', 'Free Money'

    class Status(models.TextChoices):
        PENDING = 'pending', 'En attente'
        PROCESSING = 'processing', 'En cours'
        COMPLETED = 'completed', 'Terminé'
        FAILED = 'failed', 'Échoué'
        REFUNDED = 'refunded', 'Remboursé'

    reference = models.CharField(
        max_length=50, unique=True, verbose_name='Référence transaction',
    )
    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='transactions', verbose_name='Citoyen',
    )
    dossier = models.ForeignKey(
        'dossiers.Dossier', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='transactions', verbose_name='Dossier',
    )
    provider = models.CharField(
        max_length=20, choices=Provider.choices, verbose_name='Opérateur',
    )
    amount = models.DecimalField(
        max_digits=10, decimal_places=2, verbose_name='Montant (FCFA)',
    )
    phone_number = models.CharField(
        max_length=20, verbose_name='Numéro de téléphone',
    )
    status = models.CharField(
        max_length=20, choices=Status.choices,
        default=Status.PENDING, verbose_name='Statut',
    )
    external_transaction_id = models.CharField(
        max_length=255, blank=True, default='', verbose_name='ID transaction opérateur',
    )
    receipt_url = models.URLField(
        blank=True, default='', verbose_name='URL reçu PDF',
    )
    paid_at = models.DateTimeField(
        null=True, blank=True, verbose_name='Date de paiement',
    )
    metadata = models.JSONField(
        default=dict, blank=True, verbose_name='Métadonnées',
    )

    class Meta:
        verbose_name = 'Transaction'
        verbose_name_plural = 'Transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reference']),
            models.Index(fields=['citizen']),
            models.Index(fields=['status']),
            models.Index(fields=['provider']),
        ]

    def __str__(self):
        return f'{self.reference} — {self.amount} FCFA ({self.get_status_display()})'

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = f'TXN-{uuid.uuid4().hex[:12].upper()}'
        super().save(*args, **kwargs)


# =============================================================================
# SIGNALEMENTS CITOYENS
# =============================================================================

class Report(TimeStampedModel):
    """
    Signalement citoyen (voirie, éclairage, déchets, etc.).
    Inclut géolocalisation et photo.
    """

    class Category(models.TextChoices):
        ROAD = 'road', 'Voirie'
        LIGHTING = 'lighting', 'Éclairage public'
        WASTE = 'waste', 'Déchets / Salubrité'
        WATER = 'water', 'Eau / Assainissement'
        SECURITY = 'security', 'Sécurité'
        OTHER = 'other', 'Autre'

    class Status(models.TextChoices):
        RECEIVED = 'received', 'Reçu'
        IN_PROGRESS = 'in_progress', 'En traitement'
        RESOLVED = 'resolved', 'Résolu'
        CLOSED = 'closed', 'Fermé'

    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='reports', verbose_name='Citoyen',
    )
    commune = models.ForeignKey(
        'communes.Commune', on_delete=models.CASCADE,
        related_name='reports', verbose_name='Commune',
    )
    category = models.CharField(
        max_length=20, choices=Category.choices, verbose_name='Catégorie',
    )
    title = models.CharField(max_length=255, verbose_name='Titre')
    description = models.TextField(verbose_name='Description')
    status = models.CharField(
        max_length=20, choices=Status.choices,
        default=Status.RECEIVED, verbose_name='Statut',
    )
    latitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True, verbose_name='Latitude',
    )
    longitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True, verbose_name='Longitude',
    )
    photo = models.ImageField(
        upload_to='reports/photos/', null=True, blank=True, verbose_name='Photo',
    )
    admin_notes = models.TextField(
        blank=True, default='', verbose_name='Notes administration',
    )
    resolved_at = models.DateTimeField(
        null=True, blank=True, verbose_name='Date de résolution',
    )

    class Meta:
        verbose_name = 'Signalement'
        verbose_name_plural = 'Signalements'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['status']),
            models.Index(fields=['commune']),
        ]

    def __str__(self):
        return f'{self.title} ({self.get_category_display()}) — {self.get_status_display()}'


# =============================================================================
# SONDAGES & PARTICIPATION CITOYENNE
# =============================================================================

class Survey(TimeStampedModel):
    """Sondage ou consultation citoyenne."""

    commune = models.ForeignKey(
        'communes.Commune', on_delete=models.CASCADE,
        related_name='surveys', verbose_name='Commune',
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='created_surveys', verbose_name='Créé par',
    )
    title = models.CharField(max_length=255, verbose_name='Titre')
    description = models.TextField(verbose_name='Description')
    starts_at = models.DateTimeField(verbose_name='Date de début')
    ends_at = models.DateTimeField(verbose_name='Date de fin')

    class Meta:
        verbose_name = 'Sondage'
        verbose_name_plural = 'Sondages'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    @property
    def is_open(self):
        from django.utils import timezone
        now = timezone.now()
        return self.starts_at <= now <= self.ends_at


class SurveyOption(models.Model):
    """Option de réponse pour un sondage."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    survey = models.ForeignKey(
        Survey, on_delete=models.CASCADE, related_name='options', verbose_name='Sondage',
    )
    text = models.CharField(max_length=255, verbose_name='Texte de l\'option')
    votes_count = models.PositiveIntegerField(default=0, verbose_name='Nombre de votes')

    class Meta:
        verbose_name = 'Option de sondage'
        verbose_name_plural = 'Options de sondage'

    def __str__(self):
        return f'{self.text} ({self.votes_count} votes)'


class SurveyVote(TimeStampedModel):
    """Vote d'un citoyen sur une option de sondage."""
    survey = models.ForeignKey(
        Survey, on_delete=models.CASCADE, related_name='votes', verbose_name='Sondage',
    )
    option = models.ForeignKey(
        SurveyOption, on_delete=models.CASCADE, related_name='voter_records', verbose_name='Option',
    )
    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='survey_votes', verbose_name='Citoyen',
    )

    class Meta:
        verbose_name = 'Vote'
        verbose_name_plural = 'Votes'
        unique_together = ('survey', 'citizen')  # Un vote par citoyen par sondage

    def __str__(self):
        return f'{self.citizen} → {self.option.text}'
