"""
Commune model for territorial collectivities.
"""
from django.db import models

from apps.shared.models import TimeStampedModel


class Commune(TimeStampedModel):
    """
    Represents a Senegalese commune (local government entity).
    """
    name = models.CharField(
        max_length=200,
        verbose_name='Nom',
    )
    region = models.CharField(
        max_length=100,
        verbose_name='Région',
        db_index=True,
    )
    department = models.CharField(
        max_length=100,
        verbose_name='Département',
    )
    code = models.CharField(
        max_length=10,
        unique=True,
        verbose_name='Code administratif',
    )
    address = models.TextField(
        blank=True,
        default='',
        verbose_name='Adresse',
    )
    phone = models.CharField(
        max_length=20,
        blank=True,
        default='',
        verbose_name='Téléphone',
    )
    email = models.EmailField(
        blank=True,
        default='',
        verbose_name='Email',
    )
    
    # Configuration Centralisée des Communes
    nom_commune_officiel = models.CharField(
        max_length=255, 
        blank=True, 
        null=True, 
        verbose_name="Nom officiel de la commune"
    )
    devise = models.CharField(
        max_length=255, 
        default="Un Peuple - Un But - Une Foi", 
        verbose_name="Devise"
    )
    nom_officier_etat_civil = models.CharField(
        max_length=255, 
        blank=True, 
        null=True, 
        verbose_name="Nom de l'officier d'état civil"
    )
    
    # Chemins des cachets et signatures
    chemin_cachet_communal = models.CharField(
        max_length=500, 
        blank=True, 
        null=True, 
        verbose_name="Chemin du cachet communal"
    )
    chemin_cachet_nominal = models.CharField(
        max_length=500, 
        blank=True, 
        null=True, 
        verbose_name="Chemin du cachet nominal"
    )
    chemin_signature_officier = models.CharField(
        max_length=500, 
        blank=True, 
        null=True, 
        verbose_name="Chemin de la signature de l'officier"
    )
    
    # Préfixes des actes
    prefixe_residence = models.CharField(
        max_length=20, 
        default="RES-2026-", 
        verbose_name="Préfixe Résidence"
    )
    prefixe_mariage = models.CharField(
        max_length=20, 
        default="MAR-2026-", 
        verbose_name="Préfixe Mariage"
    )
    prefixe_deces = models.CharField(
        max_length=20, 
        default="DEC-2026-", 
        verbose_name="Préfixe Décès"
    )
    
    numero_registre_courant = models.IntegerField(
        default=1, 
        verbose_name="Numéro de registre courant"
    )

    class Meta:
        verbose_name = 'Commune'
        verbose_name_plural = 'Communes'
        ordering = ['name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['region']),
            models.Index(fields=['code']),
        ]

    def __str__(self):
        return f'{self.name} ({self.region})'


class Mairie(models.Model):
    nom = models.CharField(max_length=200)
    commune = models.ForeignKey(
        Commune,
        on_delete=models.CASCADE,
        related_name='mairies'
    )
    adresse = models.CharField(max_length=300, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    telephone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    horaires = models.TextField(blank=True)
    est_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Mairie"
        verbose_name_plural = "Mairies"
        ordering = ['nom']

    def __str__(self):
        return f"{self.nom} — {self.commune.name}"
