"""
Modèle Citoyen pour le Répertoire et le Guichet Rapide de l'Etat Civil.
"""
import uuid
from django.db import models
from django.conf import settings
from datetime import date

from apps.shared.models import TimeStampedModel
from apps.shared.validators import validate_cni, validate_phone_senegal

class Citoyen(TimeStampedModel):
    """
    Modèle représentant un citoyen enregistré depuis le guichet ou le répertoire,
    qui n'a pas nécessairement un compte web (User).
    """
    
    class Gender(models.TextChoices):
        MALE = 'M', 'Masculin'
        FEMALE = 'F', 'Féminin'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    
    # --- Identité ---
    prenom = models.CharField(max_length=100, verbose_name="Prénom")
    nom = models.CharField(max_length=100, verbose_name="Nom")
    date_naissance = models.DateField(verbose_name="Date de naissance")
    lieu_naissance = models.CharField(max_length=100, blank=True, null=True, verbose_name="Lieu de naissance")
    sexe = models.CharField(
        max_length=1,
        choices=Gender.choices,
        verbose_name="Sexe"
    )
    nationalite = models.CharField(
        max_length=50,
        default="Sénégalaise",
        verbose_name="Nationalité"
    )
    nom_pere = models.CharField(max_length=150, blank=True, null=True, verbose_name="Nom complet du père")
    nom_mere = models.CharField(max_length=150, blank=True, null=True, verbose_name="Nom complet de la mère")
    
    # --- Contact ---
    telephone = models.CharField(
        max_length=20,
        validators=[validate_phone_senegal],
        verbose_name="Téléphone"
    )
    email = models.EmailField(blank=True, null=True, verbose_name="Email")
    adresse = models.TextField(blank=True, null=True, verbose_name="Adresse")
    quartier = models.CharField(max_length=100, blank=True, null=True, verbose_name="Quartier")
    commune = models.ForeignKey(
        'communes.Commune',
        on_delete=models.SET_NULL,
        null=True,
        related_name='citoyens_guichet',
        verbose_name="Commune"
    )
    
    # --- Documents ---
    numero_cni = models.CharField(
        max_length=20,
        unique=True,
        blank=True,
        null=True,
        validators=[validate_cni],
        verbose_name="Numéro CNI"
    )
    numero_passeport = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name="Numéro de passeport"
    )
    date_expiration_cni = models.DateField(
        blank=True,
        null=True,
        verbose_name="Date d'expiration CNI"
    )
    
    # --- Système ---
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='citoyens_crees',
        verbose_name="Créé par"
    )
    est_actif = models.BooleanField(default=True, verbose_name="Est actif")

    class Meta:
        app_label = 'etat_civil'
        verbose_name = "Citoyen"
        verbose_name_plural = "Citoyens"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['numero_cni']),
            models.Index(fields=['telephone']),
            models.Index(fields=['nom', 'prenom']),
        ]

    def __str__(self):
        return f"{self.prenom} {self.nom} - {self.telephone}"

    @property
    def nom_complet(self):
        return f"{self.prenom} {self.nom}".strip()

    @property
    def age(self):
        if not self.date_naissance:
            return None
        today = date.today()
        return today.year - self.date_naissance.year - ((today.month, today.day) < (self.date_naissance.month, self.date_naissance.day))
