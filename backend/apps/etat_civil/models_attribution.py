from django.db import models
from django.conf import settings
from apps.dossiers.models import Dossier

class ProfilAgent(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='profil_agent'
    )
    specialites = models.JSONField(default=list)
    disponibilite = models.BooleanField(default=True)
    charge_maximale = models.PositiveIntegerField(default=10)
    score_global = models.FloatField(default=0.0)
    temps_moyen_traitement = models.FloatField(default=0.0) # en minutes
    taux_reussite = models.FloatField(default=0.0) # en pourcentage
    taux_respect_delais = models.FloatField(default=0.0) # en pourcentage
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'attribution_profil_agent'
        verbose_name = "Profil Agent"
        verbose_name_plural = "Profils Agents"
        app_label = 'etat_civil'

    def __str__(self):
        return f"Profil Agent - {self.user.email}"

class AttributionDossier(models.Model):
    PRIORITE_CHOICES = [
        ('urgent', 'Urgent'),
        ('eleve', 'Élevé'),
        ('normal', 'Normal'),
        ('faible', 'Faible'),
    ]

    SOURCE_CHOICES = [
        ('auto', 'Automatique'),
        ('ia', 'Intelligence Artificielle'),
        ('manuel', 'Manuel'),
        ('reattribution', 'Réattribution'),
        ('superviseur', 'Superviseur'),
    ]

    dossier = models.ForeignKey(
        Dossier,
        on_delete=models.CASCADE,
        related_name='attributions'
    )
    agent_actuel = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='attributions_actuelles'
    )
    ancien_agent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='anciennes_attributions'
    )
    score_attribution = models.FloatField(default=0.0)
    niveau_priorite = models.CharField(max_length=20, choices=PRIORITE_CHOICES, default='normal')
    source_attribution = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='auto')
    justification_ia = models.TextField(blank=True, null=True)
    date_attribution = models.DateTimeField(auto_now_add=True)
    date_limite_traitement = models.DateTimeField()
    notification_24h_envoyee = models.BooleanField(default=False)
    notification_48h_envoyee = models.BooleanField(default=False)
    est_reattribution = models.BooleanField(default=False)
    responsable_attribution = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='attributions_effectuees'
    )

    class Meta:
        db_table = 'attribution_dossier'
        verbose_name = "Attribution de Dossier"
        verbose_name_plural = "Attributions de Dossiers"
        app_label = 'etat_civil'

    def __str__(self):
        return f"Attribution - Dossier {self.dossier.id} - Agent {self.agent_actuel.email}"

class JournalAttribution(models.Model):
    libelle_action = models.CharField(max_length=255)
    dossier_id = models.CharField(max_length=100)
    agent_avant = models.CharField(max_length=255, blank=True, null=True)
    agent_apres = models.CharField(max_length=255, blank=True, null=True)
    score_calcule = models.FloatField(default=0.0)
    justification = models.TextField(blank=True, null=True)
    responsable = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='actions_journal'
    )
    timestamp = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(default=dict)

    class Meta:
        db_table = 'attribution_journal'
        verbose_name = "Journal Attribution"
        verbose_name_plural = "Journaux Attributions"
        ordering = ['-timestamp']
        app_label = 'etat_civil'

    def __str__(self):
        return f"{self.timestamp} - {self.libelle_action} - Dossier {self.dossier_id}"
