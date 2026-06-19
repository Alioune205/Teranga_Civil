"""
Mock pour les passerelles de paiement mobile (Wave, Orange Money, Free Money).

Simule l'initiation et le suivi des transactions de paiement.
En production, remplacer par les SDK/API officiels de chaque opérateur.
"""
import re
import time
import uuid
import random
from decimal import Decimal
from .base import BaseMockClient


class PaymentGatewayMock(BaseMockClient):
    """
    Client de simulation pour les opérateurs de paiement mobile au Sénégal.

    Méthodes disponibles :
        - ping() : vérifier la disponibilité
        - initiate_payment(amount, phone_number, provider) : démarrer un paiement
        - check_transaction_status(transaction_id) : vérifier le statut
        - refund_transaction(transaction_id, reason) : initier un remboursement
    """

    # Regex pour les numéros sénégalais (77, 78, 76, 70, 75)
    SN_PHONE_REGEX = re.compile(r'^(\+221)?(7[05678]\d{7})$')

    # Frais par opérateur (en pourcentage)
    PROVIDER_FEES = {
        'wave': Decimal('0.01'),        # 1%
        'orange_money': Decimal('0.02'),  # 2%
        'free_money': Decimal('0.015'),   # 1.5%
    }

    def __init__(self):
        super().__init__("PAYMENT")

    def ping(self):
        return {"status": "up", "service": "Payment Gateway"}

    def initiate_payment(self, amount, phone_number, provider='wave'):
        """
        Initie un paiement mobile.

        Args:
            amount: Montant en FCFA.
            phone_number: Numéro de téléphone du payeur.
            provider: Opérateur ('wave', 'orange_money', 'free_money').

        Returns:
            dict: Résultat avec transaction_id et URL de paiement.
        """
        self.log_call("initiate_payment", {
            "amount": str(amount), "phone": phone_number, "provider": provider,
        })

        # Validation du montant
        try:
            amount = Decimal(str(amount))
        except Exception:
            return {
                "success": False,
                "error_code": "INVALID_AMOUNT",
                "error": "Le montant doit être un nombre valide.",
            }

        if amount <= 0:
            return {
                "success": False,
                "error_code": "INVALID_AMOUNT",
                "error": "Le montant doit être supérieur à 0 FCFA.",
            }

        if amount > Decimal('1000000'):
            return {
                "success": False,
                "error_code": "AMOUNT_TOO_HIGH",
                "error": "Le montant maximum par transaction est de 1 000 000 FCFA.",
            }

        # Validation du provider
        if provider not in self.PROVIDER_FEES:
            return {
                "success": False,
                "error_code": "INVALID_PROVIDER",
                "error": f"Opérateur invalide. Choix : {', '.join(self.PROVIDER_FEES.keys())}.",
            }

        # Simulation de latence réseau
        time.sleep(0.5)

        # Calcul des frais
        fee_rate = self.PROVIDER_FEES[provider]
        fees = round(amount * fee_rate, 2)

        transaction_id = str(uuid.uuid4())
        return {
            "success": True,
            "transaction_id": transaction_id,
            "payment_url": f"https://pay.{provider}.sn/checkout/{transaction_id}",
            "amount": str(amount),
            "fees": str(fees),
            "total": str(amount + fees),
            "provider": provider,
            "status": "pending",
            "expires_in": 900,  # 15 minutes
        }

    def check_transaction_status(self, transaction_id):
        """
        Vérifie le statut d'une transaction.

        Args:
            transaction_id: ID de la transaction à vérifier.

        Returns:
            dict: Statut actuel de la transaction.
        """
        self.log_call("check_status", {"transaction_id": transaction_id})

        if not transaction_id:
            return {
                "success": False,
                "error_code": "MISSING_ID",
                "error": "L'identifiant de transaction est requis.",
            }

        time.sleep(0.2)

        return {
            "success": True,
            "transaction_id": transaction_id,
            "status": "completed",
            "receipt_number": f"RCPT-{uuid.uuid4().hex[:8].upper()}",
            "paid_at": "2025-01-15T14:30:00+00:00",
        }

    def refund_transaction(self, transaction_id, reason=''):
        """
        Initie un remboursement pour une transaction.

        Args:
            transaction_id: ID de la transaction à rembourser.
            reason: Motif du remboursement.

        Returns:
            dict: Confirmation du remboursement.
        """
        self.log_call("refund", {
            "transaction_id": transaction_id, "reason": reason,
        })

        if not transaction_id:
            return {
                "success": False,
                "error_code": "MISSING_ID",
                "error": "L'identifiant de transaction est requis.",
            }

        time.sleep(0.3)

        return {
            "success": True,
            "transaction_id": transaction_id,
            "refund_id": f"REF-{uuid.uuid4().hex[:8].upper()}",
            "status": "refunded",
            "reason": reason,
        }
