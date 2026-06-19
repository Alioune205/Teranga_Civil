import uuid
from django.db import models
from django.core.exceptions import ValidationError
from django.conf import settings

class PaymentType(models.TextChoices):
    CARD = 'card', 'Carte bancaire (CB/Visa/Mastercard)'
    WAVE = 'wave', 'Mobile Money Wave'
    ORANGE_MONEY = 'orange_money', 'Mobile Money Orange Money'
    FREE_MONEY = 'free_money', 'Mobile Money Free Money'
    TRANSFER = 'transfer', 'Virement bancaire'
    AGENCY = 'agency', 'Paiement en agence'
    CASH = 'cash', 'Espèces (caisse)'

class PaymentStatus(models.TextChoices):
    PENDING = 'pending', 'En attente'
    SUCCESS = 'success', 'Validé'
    PAID = 'paid', 'Payé'
    FAILED = 'failed', 'Échoué'
    REFUNDED = 'refunded', 'Remboursé'
    CANCELLED = 'cancelled', 'Annulé'

class PaymentTransaction(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reference = models.CharField(max_length=100, unique=True, verbose_name="Référence")
    amount = models.DecimalField(max_digits=12, decimal_places=2, verbose_name="Montant")
    currency = models.CharField(max_length=10, default='XOF', verbose_name="Devise")
    payment_type = models.CharField(max_length=30, choices=PaymentType.choices, verbose_name="Type de paiement")
    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING, verbose_name="Statut")
    payer_name = models.CharField(max_length=150, verbose_name="Nom du payeur")
    payer_id = models.CharField(max_length=100, verbose_name="Identifiant du payeur")
    service_label = models.CharField(max_length=200, verbose_name="Libellé du service")
    
    # Nouveaux champs pour le paiement au guichet
    dossier = models.ForeignKey(
        'dossiers.Dossier',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments',
        verbose_name="Dossier"
    )
    agent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments_received',
        verbose_name="Agent"
    )
    receipt_number = models.CharField(
        max_length=50,
        unique=True,
        null=True,
        blank=True,
        verbose_name="Numéro de reçu"
    )
    transaction_reference = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name="Référence externe"
    )
    comment = models.TextField(
        blank=True,
        default='',
        verbose_name="Commentaire"
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date de création")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Date de modification")

    class Meta:
        db_table = 'payment_transactions'
        ordering = ['-created_at']

    def __str__(self):
        return f"Transaction {self.reference} — {self.amount} {self.currency} ({self.status})"

    def save(self, *args, **kwargs):
        # Puisque self.pk est généré par défaut, on vérifie s'il existe déjà dans la base
        if PaymentTransaction.objects.filter(pk=self.pk).exists():
            original = PaymentTransaction.objects.get(pk=self.pk)
            # Ne vérifier que les champs qui ne doivent pas changer
            fields_to_check = [
                'id', 'reference', 'amount', 'currency', 'payment_type',
                'payer_name', 'payer_id', 'service_label', 'created_at'
            ]
            for field in fields_to_check:
                if getattr(self, field) != getattr(original, field):
                    raise ValidationError(f"Le champ '{field}' ne peut pas être modifié après la création.")
        super().save(*args, **kwargs)


class TreasuryTransfer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction = models.ForeignKey(
        PaymentTransaction,
        on_delete=models.CASCADE,
        related_name='treasury_transfers',
        verbose_name="Transaction"
    )
    transferred_at = models.DateTimeField(verbose_name="Date de transfert")
    transfer_reference = models.CharField(max_length=100, verbose_name="Référence de transfert")
    validated_by = models.CharField(max_length=50, default='system', verbose_name="Validé par")

    class Meta:
        db_table = 'treasury_transfers'
        ordering = ['-transferred_at']

    def __str__(self):
        return f"Transfert {self.transfer_reference} pour {self.transaction.reference}"

    def save(self, *args, **kwargs):
        if self.validated_by != 'system':
            raise ValidationError("La validation doit être effectuée par le système uniquement.")
        super().save(*args, **kwargs)
