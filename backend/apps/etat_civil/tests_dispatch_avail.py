from django.test import TestCase
from rest_framework.test import APIClient
from apps.users.models import User
from apps.communes.models import Commune
from apps.etat_civil.services.service_attribution import ServiceAttribution
from unittest.mock import patch
from datetime import datetime, timezone as dt_tz

class DispatchAvailTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.commune = Commune.objects.create(name='Test Commune')
        self.super_admin = User.objects.create_user(email='super@test.com', password='pwd', role='super_admin', first_name='S', last_name='A')
        self.supervisor = User.objects.create_user(email='sup@test.com', password='pwd', role='civil_admin_supervisor', commune=self.commune, first_name='S', last_name='V')
        self.agent = User.objects.create_user(email='agent@test.com', password='pwd', role='agent', commune=self.commune, first_name='A', last_name='G')
        
    def test_supervisor_403(self):
        self.client.force_authenticate(user=self.supervisor)
        resp = self.client.patch(f'/api/users/{self.agent.id}/toggle_break/')
        self.assertEqual(resp.status_code, 403)
        
    def test_superadmin_200(self):
        self.client.force_authenticate(user=self.super_admin)
        resp = self.client.patch(f'/api/users/{self.agent.id}/toggle_break/')
        self.assertEqual(resp.status_code, 200)
        self.agent.refresh_from_db()
        self.assertTrue(self.agent.is_on_break)

    @patch('apps.etat_civil.services.service_attribution.timezone.now')
    def test_auto_pause(self, mock_now):
        mock_now.return_value = datetime(2025, 1, 1, 14, 0, tzinfo=dt_tz.utc)
        service = ServiceAttribution()
        class DummyDossier:
            commune_id = self.commune.id
        result, msg = service.attribuer(DummyDossier())
        self.assertIsNone(result)
        self.assertIn('Pause automatique en cours', msg)
