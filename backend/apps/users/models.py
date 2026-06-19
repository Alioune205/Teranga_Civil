"""
User and CitizenProfile models for TERANGA CIVIL.
"""
import uuid
from django.utils import timezone

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from ..shared.validators import validate_phone_senegal, validate_cni
from .managers import CustomUserManager


class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom User model using email as the unique identifier.
    Supports RBAC via the `role` field.
    """

    class Role(models.TextChoices):
        CITIZEN = 'citizen', 'Citoyen'
        AGENT = 'agent', 'Agent'
        CIVIL_ADMIN = 'civil_admin', 'Administrateur de mairie'
        CIVIL_ADMIN_SUPERVISOR = 'civil_admin_supervisor', 'Administrateur général de mairie'
        SUPER_ADMIN = 'super_admin', 'Super administrateur'

    class AgentCapability(models.TextChoices):
        RECEPTION = 'reception', 'Réception'
        VERIFICATION = 'verification', 'Vérification'
        APPROVAL = 'approval', 'Approbation'
        GENERATION_COPIE_LITTERALE = 'generation_copie_litterale', 'Génération Copie Littérale'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    email = models.EmailField(
        unique=True,
        verbose_name='Adresse email',
    )
    phone = models.CharField(
        max_length=20,
        unique=True,
        blank=True,
        null=True,
        validators=[validate_phone_senegal],
        verbose_name='Téléphone',
    )
    first_name = models.CharField(
        max_length=100,
        verbose_name='Prénom',
    )
    last_name = models.CharField(
        max_length=100,
        verbose_name='Nom',
    )
    role = models.CharField(
        max_length=25,
        choices=Role.choices,
        default=Role.CITIZEN,
        verbose_name='Rôle',
        db_index=True,
    )
    agent_capabilities = models.JSONField(
        default=list,
        blank=True,
        verbose_name="Capacités de l'agent",
        help_text="Liste des étapes pour lesquelles cet agent est habilité (ex: ['reception', 'verification'])"
    )
    commune = models.ForeignKey(
        'communes.Commune',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
        verbose_name='Commune',
    )
    avatar = models.ImageField(
        upload_to='users/avatars/',
        null=True,
        blank=True,
        verbose_name='Avatar',
    )
    is_verified = models.BooleanField(
        default=False,
        verbose_name='Vérifié',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Actif',
    )
    is_on_break = models.BooleanField(
        default=False,
        verbose_name='En pause',
    )
    break_started_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Début de pause',
    )
    is_dispatch_eligible = models.BooleanField(
        default=True,
        verbose_name='Éligible au dispatch',
    )
    is_staff = models.BooleanField(
        default=False,
        verbose_name='Staff',
    )
    must_change_password = models.BooleanField(
        default=False,
        verbose_name='Doit changer de mot de passe',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de création',
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Date de modification',
    )

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        verbose_name = 'Utilisateur'
        verbose_name_plural = 'Utilisateurs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['role']),
            models.Index(fields=['commune']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f'{self.first_name} {self.last_name} ({self.email})'

    @property
    def full_name(self):
        return f'{self.first_name} {self.last_name}'

    @property
    def is_admin_staff(self):
        """Check if user has any administrative role."""
        return self.role in [
            self.Role.AGENT,
            self.Role.CIVIL_ADMIN,
            self.Role.CIVIL_ADMIN_SUPERVISOR,
            self.Role.SUPER_ADMIN,
        ]


class CitizenProfile(models.Model):
    """
    Extended profile for citizens with personal information.
    Auto-created when a citizen user is registered.
    """

    class Gender(models.TextChoices):
        MALE = 'M', 'Masculin'
        FEMALE = 'F', 'Féminin'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile',
        verbose_name='Utilisateur',
    )
    address = models.TextField(
        blank=True,
        default='',
        verbose_name='Adresse',
    )
    cni_number = models.CharField(
        max_length=20,
        unique=True,
        blank=True,
        null=True,
        validators=[validate_cni],
        verbose_name='Numéro CNI',
    )
    date_of_birth = models.DateField(
        null=True,
        blank=True,
        verbose_name='Date de naissance',
    )
    place_of_birth = models.CharField(
        max_length=100,
        blank=True,
        default='',
        verbose_name='Lieu de naissance',
    )
    gender = models.CharField(
        max_length=1,
        choices=Gender.choices,
        blank=True,
        default='',
        verbose_name='Genre',
    )
    profession = models.CharField(
        max_length=100,
        blank=True,
        default='',
        verbose_name='Profession',
    )
    photo = models.ImageField(
        upload_to='profiles/photos/',
        null=True,
        blank=True,
        verbose_name='Photo',
    )
    cni_document = models.FileField(
        upload_to='profiles/cni/',
        null=True,
        blank=True,
        verbose_name='Document CNI (Recto/Verso)',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de création',
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Date de modification',
    )

    class Meta:
        verbose_name = 'Profil citoyen'



class OTPCode(models.Model):
    """
    Modèle pour gérer les codes OTP (One Time Password) pour la vérification de téléphone/email.
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    identifier = models.CharField(
        max_length=100,
        verbose_name='Identifiant (Email ou Téléphone)',
        help_text='Le numéro de téléphone ou email à vérifier',
    )
    code = models.CharField(
        max_length=6,
        verbose_name='Code OTP',
    )
    is_used = models.BooleanField(
        default=False,
        verbose_name='Est utilisé',
    )
    expires_at = models.DateTimeField(
        verbose_name="Date d'expiration",
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de création',
    )

    class Meta:
        verbose_name = 'Code OTP'
        verbose_name_plural = 'Codes OTP'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['identifier', 'code']),
            models.Index(fields=['is_used']),
        ]

    def __str__(self):
        return f'OTP {self.code} pour {self.identifier}'

    @property
    def is_valid(self):
        return not self.is_used and timezone.now() <= self.expires_at


class LoginHistory(models.Model):
    """
    Modèle pour stocker l'historique de connexion des utilisateurs.
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='login_history',
        verbose_name='Utilisateur'
    )
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        verbose_name='Adresse IP'
    )
    user_agent = models.TextField(
        null=True,
        blank=True,
        verbose_name='User Agent'
    )
    login_time = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date et heure de connexion'
    )
    
    class Meta:
        verbose_name = 'Historique de connexion'
        verbose_name_plural = 'Historiques de connexion'
        ordering = ['-login_time']

    def __str__(self):
        return f"{self.user.email} connecté à {self.login_time}"
