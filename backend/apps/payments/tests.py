from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from apps.users.models import User
from apps.dossiers.models import Dossier
from apps.communes.models import Commune
from apps.payments.models import PaymentTransaction, PaymentStatus, PaymentType

class PaymentGuichetTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        
        # Créer une commune
        self.commune = Commune.objects.create(
            name="Keur Massar",
            region="Dakar",
            department="Keur Massar",
            code="KM01"
        )
        
        # Créer un agent de réception
        self.agent = User.objects.create_user(
            email="reception@terangacivil.sn",
            password="password123",
            first_name="Agent",
            last_name="Réception",
            role="agent",
            agent_capabilities=["reception"],
            commune=self.commune
        )
        
        # Créer un citoyen
        self.citizen = User.objects.create_user(
            email="citoyen@gmail.com",
            password="password123",
            first_name="Abdou",
            last_name="Diop",
            role="citizen",
            commune=self.commune
        )
        
        # Créer un dossier brouillon
        self.dossier = Dossier.objects.create(
            type="residence_certificate",
            status=Dossier.Status.DRAFT,
            citizen=self.citizen,
            commune=self.commune
        )
        
        # Authentifier l'agent
        self.client.force_authenticate(user=self.agent)

    def test_register_guichet_payment_success(self):
        url = reverse('payment-guichet-register')
        data = {
            'dossier_id': str(self.dossier.id),
            'amount': 500.00,
            'payment_type': 'cash',
            'comment': 'Paiement au comptant'
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['success'], True)
        
        # Vérifier que le dossier a été mis à jour
        self.dossier.refresh_from_db()
        self.assertEqual(self.dossier.status, Dossier.Status.SUBMITTED)
        
        # Vérifier que la transaction a été créée en base
        tx = PaymentTransaction.objects.get(dossier=self.dossier)
        self.assertEqual(tx.amount, 500.00)
        self.assertEqual(tx.status, PaymentStatus.PAID)
        self.assertEqual(tx.agent, self.agent)
        self.assertIsNotNone(tx.receipt_number)

    def test_register_guichet_payment_mobile_requires_reference(self):
        url = reverse('payment-guichet-register')
        data = {
            'dossier_id': str(self.dossier.id),
            'amount': 500.00,
            'payment_type': 'wave', # Mobile
            'transaction_reference': '' # Vide -> doit échouer
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_guichet_payment_invalid_amount(self):
        url = reverse('payment-guichet-register')
        data = {
            'dossier_id': str(self.dossier.id),
            'amount': 300.00, # Moins que les 500 requis
            'payment_type': 'cash',
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("montant minimum", response.data.get('message', '').lower())

    def test_download_receipt_pdf(self):
        # Créer une transaction de paiement existante
        tx = PaymentTransaction.objects.create(
            reference="TX_TEST_RECEIPT",
            amount=500.00,
            payment_type=PaymentType.CASH,
            status=PaymentStatus.PAID,
            payer_name=self.citizen.full_name,
            payer_id=self.citizen.phone or "N/A",
            service_label="Frais de traitement",
            dossier=self.dossier,
            agent=self.agent,
            receipt_number="REC-TEST-1234"
        )
        
        url = reverse('payment-receipt-download', kwargs={'pk': tx.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')
