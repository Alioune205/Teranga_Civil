"""
Dossier and DossierComment models for administrative requests.
"""
from django.conf import settings
from django.db import models

from apps.shared.models import TimeStampedModel
from apps.shared.utils import generate_reference


class Dossier(TimeStampedModel):
    """
    Represents an administrative request (demande) made by a citizen.
    Follows the workflow: draft → submitted → in_review → approved/rejected → completed
    """

    class Type(models.TextChoices):
        BIRTH_CERTIFICATE = 'birth_certificate', 'Acte de naissance'
        MARRIAGE_CERTIFICATE = 'marriage_certificate', 'Acte de mariage'
        DEATH_CERTIFICATE = 'death_certificate', 'Acte de décès'
        RESIDENCE_CERTIFICATE = 'residence_certificate', 'Certificat de résidence'
        REGULARISATION = 'regularisation', 'Demande de régularisation'
        AUTORISATION_CONSTRUIRE = 'autorisation_construire', 'Autorisation de construire'
        MUTATION_PARCELLE = 'mutation_parcelle', 'Mutation de parcelle'
        OTHER = 'other', 'Autre'

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Brouillon'
        SUBMITTED = 'submitted', 'Soumis'
        IN_REVIEW = 'in_review', 'En cours de vérification'
        APPROVED = 'approved', 'Approuvé'
        REJECTED = 'rejected', 'Rejeté'
        COMPLETED = 'completed', 'Terminé'

    reference = models.CharField(
        max_length=30,
        unique=True,
        verbose_name='Référence',
        db_index=True,
    )
    type = models.CharField(
        max_length=30,
        choices=Type.choices,
        verbose_name='Type de dossier',
        db_index=True,
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
        verbose_name='Statut',
        db_index=True,
    )
    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='dossiers',
        verbose_name='Citoyen',
    )
    assigned_agent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_dossiers',
        verbose_name='Agent responsable',
    )
    citoyen_guichet = models.ForeignKey(
        'etat_civil.Citoyen',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='dossiers',
        verbose_name='Citoyen (Guichet)',
    )
    commune = models.ForeignKey(
        'communes.Commune',
        on_delete=models.CASCADE,
        related_name='dossiers',
        verbose_name='Commune',
    )
    notes = models.TextField(
        blank=True,
        default='',
        verbose_name='Notes',
    )
    metadata = models.JSONField(
        default=dict,
        blank=True,
        verbose_name='Métadonnées (Formulaire dynamique)',
    )
    rejection_reason = models.TextField(
        blank=True,
        default='',
        verbose_name='Motif de rejet',
    )
    submitted_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date de soumission',
    )
    reviewed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date de vérification',
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date de complétion',
    )
    statut = models.CharField(max_length=20, choices=[
        ('EN_ATTENTE', 'En attente'),
        ('EN_COURS', 'En cours'),
        ('EN_APPROBATION', 'Soumis au Maire'),
        ('APPROUVE', 'Approuvé'),
        ('REJETE', 'Rejeté'),
    ], default='EN_ATTENTE')
    agent_traitant = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL, null=True, blank=True,
        related_name='dossiers_traites',
        limit_choices_to={'role': 'agent'}
    )
    date_soumission_maire = models.DateTimeField(null=True, blank=True)
    decision_maire = models.TextField(blank=True, default='')
    date_decision = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'Dossier'
        verbose_name_plural = 'Dossiers'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reference']),
            models.Index(fields=['type']),
            models.Index(fields=['status']),
            models.Index(fields=['citizen']),
            models.Index(fields=['commune']),
            models.Index(fields=['status', 'commune']),
        ]

    def __str__(self):
        return f'{self.reference} — {self.get_type_display()} ({self.get_status_display()})'

    def save(self, *args, **kwargs):
        if not self.reference:
            prefix = 'DOS'
            if self.type == self.Type.MARRIAGE_CERTIFICATE:
                prefix = 'MAR'
            elif self.type == self.Type.DEATH_CERTIFICATE:
                prefix = 'DEC'
            elif self.type == self.Type.RESIDENCE_CERTIFICATE:
                prefix = 'RES'
            elif self.type == self.Type.BIRTH_CERTIFICATE:
                prefix = 'NAI'
            elif self.type == self.Type.REGULARISATION:
                prefix = 'REG'
            self.reference = generate_reference(prefix)
        super().save(*args, **kwargs)


class DossierComment(TimeStampedModel):
    """
    Comment on a dossier, from either the citizen or an agent.
    """
    dossier = models.ForeignKey(
        Dossier,
        on_delete=models.CASCADE,
        related_name='comments',
        verbose_name='Dossier',
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='dossier_comments',
        verbose_name='Auteur',
    )
    content = models.TextField(
        verbose_name='Contenu',
    )

    class Meta:
        verbose_name = 'Commentaire'
        verbose_name_plural = 'Commentaires'
        ordering = ['created_at']

    def __str__(self):
        return f'Commentaire de {self.author.full_name} sur {self.dossier.reference}'


class RegistreCivil(TimeStampedModel):
    numero_registre = models.CharField(max_length=50, verbose_name='Numéro de registre')
    annee_registre = models.IntegerField(verbose_name='Année de registre')
    type_acte = models.CharField(max_length=30, choices=Dossier.Type.choices, verbose_name='Type d\'acte')
    nom_complet_personne = models.CharField(max_length=255, verbose_name='Nom complet sur le registre')
    date_naissance_personne = models.DateField(verbose_name='Date de naissance sur le registre')
    conjoint_nom_complet = models.CharField(max_length=255, blank=True, null=True, verbose_name='Nom complet du conjoint')
    commune = models.ForeignKey('communes.Commune', on_delete=models.CASCADE, related_name='registres', verbose_name='Commune de déclaration')
    
    # Nouveaux champs pour enrichissement des certificats
    nom_pere = models.CharField(max_length=255, blank=True, null=True, verbose_name='Nom du père')
    nom_mere = models.CharField(max_length=255, blank=True, null=True, verbose_name='Nom de la mère')
    sexe = models.CharField(max_length=1, choices=[('M', 'Masculin'), ('F', 'Féminin')], blank=True, null=True, verbose_name='Sexe')
    lieu_naissance = models.CharField(max_length=255, blank=True, null=True, verbose_name='Lieu de naissance')
    profession_pere = models.CharField(max_length=255, blank=True, null=True, verbose_name='Profession du père')
    profession_mere = models.CharField(max_length=255, blank=True, null=True, verbose_name='Profession de la mère')

    class Meta:
        verbose_name = 'Registre Civil (Simulation)'
        verbose_name_plural = 'Registres Civils (Simulation)'
        ordering = ['-annee_registre', 'numero_registre']
        unique_together = [('numero_registre', 'annee_registre', 'commune', 'type_acte')]

    def __str__(self):
        return f'{self.numero_registre}/{self.annee_registre} - {self.nom_complet_personne}'

