from django.test import TestCase
from rest_framework.test import APIClient
from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.payments.models import PaymentTransaction

class TransactionScopeTests(TestCase):
    def setUp(self):
        from unittest.mock import patch
        self.patcher_notif = patch('apps.notifications.services.FCMService.send_notification_to_user')
        self.mock_notify = self.patcher_notif.start()
        
        self.patcher = patch('apps.etat_civil.signals_attribution.attribuer_dossier_async.delay')
        self.mock_delay = self.patcher.start()

        self.client = APIClient()
        self.commune_a = Commune.objects.create(name="Commune Test A", code="TEST_CA_999", region="Dakar")
        self.commune_b = Commune.objects.create(name="Commune Test B", code="TEST_CB_999", region="Thies")

        self.super_admin = User.objects.create_user(
            email="super@test.local", password="password", first_name="S", last_name="A", role="super_admin", is_active=True
        )
        self.supervisor_a = User.objects.create_user(
            email="supervisor_a@test.local", password="password", first_name="S", last_name="V", role="civil_admin_supervisor", commune=self.commune_a, is_active=True
        )
        self.civil_a = User.objects.create_user(
            email="civil_a@test.local", password="password", first_name="C", last_name="A", role="civil_admin", commune=self.commune_a, is_active=True
        )
        self.citizen = User.objects.create_user(
            email="citizen@test.local", password="password", first_name="Cit", last_name="Z", role="citizen", is_active=True
        )

        self.dossier_a = Dossier.objects.create(
            commune=self.commune_a, type="naissance", status="submitted", citizen=self.citizen
        )
        self.dossier_b = Dossier.objects.create(
            commune=self.commune_b, type="mariage", status="submitted", citizen=self.citizen
        )

        self.tx_a = PaymentTransaction.objects.create(
            dossier=self.dossier_a, reference="TX_A", amount=1000, status="success", payment_type="orange_money"
        )
        self.tx_b = PaymentTransaction.objects.create(
            dossier=self.dossier_b, reference="TX_B", amount=2000, status="success", payment_type="wave"
        )

    def test_super_admin_can_see_all_transactions(self):
        self.client.force_authenticate(user=self.super_admin)
        response = self.client.get('/api/v1/admin/transactions')
        self.assertEqual(response.status_code, 200)
        refs = [t['reference'] for t in response.data['data']['results']]
        self.assertIn('TX_A', refs)
        self.assertIn('TX_B', refs)

    def test_supervisor_can_see_only_commune_transactions(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get('/api/v1/admin/transactions')
        self.assertEqual(response.status_code, 200)
        refs = [t['reference'] for t in response.data['data']['results']]
        self.assertIn('TX_A', refs)
        self.assertNotIn('TX_B', refs)

    def test_supervisor_stats_scoped_to_commune(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get('/api/v1/admin/transactions/stats')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['data']['total_amount'], 1000)

    def test_super_admin_stats_include_all(self):
        self.client.force_authenticate(user=self.super_admin)
        response = self.client.get('/api/v1/admin/transactions/stats')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['data']['total_amount'], 3000)

    def test_civil_admin_cannot_access_transactions(self):
        self.client.force_authenticate(user=self.civil_a)
        response = self.client.get('/api/v1/admin/transactions')
        self.assertEqual(response.status_code, 403)

    def tearDown(self):
        self.patcher.stop()
        self.patcher_notif.stop()
