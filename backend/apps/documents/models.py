"""
Document model for file attachments on dossiers.
"""
from django.conf import settings
from django.db import models

from apps.shared.models import TimeStampedModel
from apps.shared.validators import validate_document_file


def document_upload_path(instance, filename):
    """Generate upload path: documents/<dossier_id>/<filename>"""
    return f'documents/{instance.dossier_id}/{filename}'


class Document(TimeStampedModel):
    """
    File attachment linked to a dossier.
    Supports OCR status tracking for future AI integration (DEV 2).
    """

    class FileType(models.TextChoices):
        PDF = 'pdf', 'PDF'
        IMAGE = 'image', 'Image'
        SCAN = 'scan', 'Scan'

    class OCRStatus(models.TextChoices):
        PENDING = 'pending', 'En attente'
        PROCESSING = 'processing', 'En cours'
        COMPLETED = 'completed', 'Terminé'
        FAILED = 'failed', 'Échoué'

    dossier = models.ForeignKey(
        'dossiers.Dossier',
        on_delete=models.CASCADE,
        related_name='documents',
        verbose_name='Dossier',
    )
    file = models.FileField(
        upload_to=document_upload_path,
        validators=[validate_document_file],
        verbose_name='Fichier',
    )
    original_filename = models.CharField(
        max_length=255,
        verbose_name='Nom original',
    )
    file_type = models.CharField(
        max_length=10,
        choices=FileType.choices,
        verbose_name='Type de fichier',
    )
    file_size = models.IntegerField(
        verbose_name='Taille (bytes)',
    )
    description = models.CharField(
        max_length=255,
        blank=True,
        default='',
        verbose_name='Description',
    )
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='uploaded_documents',
        verbose_name='Téléversé par',
    )
    # OCR fields (for DEV 2 / AI team)
    ocr_status = models.CharField(
        max_length=15,
        choices=OCRStatus.choices,
        default=OCRStatus.PENDING,
        verbose_name='Statut OCR',
    )
    ocr_text = models.TextField(
        blank=True,
        default='',
        verbose_name='Texte OCR',
    )
    # Champs intégrité & sécurité (ajoutés fix bilan intégration 14/06)
    sha256_hash = models.CharField(
        max_length=64,
        blank=True,
        default='',
        verbose_name='Hash SHA-256',
        help_text='Empreinte SHA-256 du fichier uploadé (anti-doublon).',
    )
    mime_type = models.CharField(
        max_length=100,
        blank=True,
        default='',
        verbose_name='Type MIME',
        help_text='Type MIME détecté lors de l\'upload (ex: image/jpeg, application/pdf).',
    )

    class Meta:
        verbose_name = 'Document'
        verbose_name_plural = 'Documents'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['dossier']),
            models.Index(fields=['uploaded_by']),
            models.Index(fields=['ocr_status']),
            models.Index(fields=['sha256_hash']),
        ]

    def __str__(self):
        return f'{self.original_filename} ({self.dossier.reference})'

    def save(self, *args, **kwargs):
        if self.file and not self.original_filename:
            self.original_filename = self.file.name
        if self.file and not self.file_size:
            self.file_size = self.file.size
        if self.file and not self.file_type:
            ext = self.file.name.rsplit('.', 1)[-1].lower()
            if ext == 'pdf':
                self.file_type = self.FileType.PDF
            elif ext in ('jpg', 'jpeg', 'png'):
                self.file_type = self.FileType.IMAGE
            else:
                self.file_type = self.FileType.SCAN
        super().save(*args, **kwargs)


def certificate_upload_path(instance, filename):
    """Generate upload path: certificates/<dossier_ref>/<filename>"""
    return f'certificates/{instance.dossier.reference}/{filename}'


class TimbreFiscal(TimeStampedModel):
    """
    Timbre fiscal fictif lié à un certificat généré.
    Chaque timbre est unique et traçable.
    """
    import uuid as _uuid

    id = models.UUIDField(primary_key=True, default=_uuid.uuid4, editable=False)
    reference = models.CharField(
        max_length=30, unique=True,
        verbose_name='Référence du timbre',
    )
    montant = models.DecimalField(
        max_digits=10, decimal_places=2, default=500.00,
        verbose_name='Montant (FCFA)',
    )
    is_used = models.BooleanField(default=False, verbose_name='Utilisé')

    class Meta:
        verbose_name = 'Timbre Fiscal'
        verbose_name_plural = 'Timbres Fiscaux'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.reference} — {self.montant} FCFA'

    def save(self, *args, **kwargs):
        if not self.reference:
            import uuid
            self.reference = f'TIM-{uuid.uuid4().hex[:8].upper()}'
        super().save(*args, **kwargs)


class GeneratedCertificate(TimeStampedModel):
    """
    Certificat officiel généré (PDF) avec liaison cryptographique.
    Le hash inclut les données du dossier ET le hash SHA-256 du PDF lui-même,
    empêchant toute falsification du document physique.
    """
    import uuid as _uuid

    id = models.UUIDField(primary_key=True, default=_uuid.uuid4, editable=False)
    dossier = models.OneToOneField(
        'dossiers.Dossier',
        on_delete=models.CASCADE,
        related_name='certificate',
        verbose_name='Dossier',
    )
    officier = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='signed_certificates',
        verbose_name='Officier signataire',
    )
    pdf_file = models.FileField(
        upload_to=certificate_upload_path,
        verbose_name='Fichier PDF',
    )
    # Cryptographic fields
    data_payload = models.TextField(
        verbose_name='Payload signé (données brutes)',
        help_text='ref|commune|nom|date_naissance|officier_id|pdf_sha256',
    )
    pdf_sha256 = models.CharField(
        max_length=64,
        verbose_name='Hash SHA-256 du PDF',
    )
    hmac_signature = models.CharField(
        max_length=64,
        verbose_name='Signature HMAC-SHA256',
    )
    timbre = models.OneToOneField(
        TimbreFiscal,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='certificate',
        verbose_name='Timbre fiscal',
    )
    # Seal/stamp metadata
    cachet_communal_svg = models.CharField(
        max_length=255, blank=True, default='',
        verbose_name='Chemin SVG cachet communal',
    )
    signature_officier_svg = models.CharField(
        max_length=255, blank=True, default='',
        verbose_name='Chemin SVG signature officier',
    )

    class Meta:
        verbose_name = 'Certificat Généré'
        verbose_name_plural = 'Certificats Générés'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['dossier']),
            models.Index(fields=['hmac_signature']),
        ]

    def __str__(self):
        return f'Certificat {self.dossier.reference} — signé par {self.officier}'

