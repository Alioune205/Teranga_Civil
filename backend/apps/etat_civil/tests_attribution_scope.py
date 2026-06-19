from django.test import TestCase
from rest_framework.test import APIClient
from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier, JournalAttribution

class AttributionScopeTests(TestCase):
    def setUp(self):
        from unittest.mock import patch
        self.patcher_notif = patch('apps.notifications.services.FCMService.send_notification_to_user')
        self.mock_notify = self.patcher_notif.start()
        
        # Le signal attribuer_dossier_async.delay plante s'il essaie de joindre Redis,
        # on le mocke pour ces tests qui vérifient uniquement les scopes.
        self.patcher_celery = patch('apps.etat_civil.signals_attribution.attribuer_dossier_async.delay')
        self.mock_delay = self.patcher_celery.start()

        self.client = APIClient()
        self.commune_a = Commune.objects.create(name="Commune Test A", code="TEST_CA_999", region="Dakar")
        self.commune_b = Commune.objects.create(name="Commune Test B", code="TEST_CB_999", region="Thies")

        self.super_admin = User.objects.create_user(
            email="super@test.local", password="password", first_name="S", last_name="A", role="super_admin", is_active=True
        )
        self.supervisor_a = User.objects.create_user(
            email="supervisor_a@test.local", password="password", first_name="S", last_name="V", role="civil_admin_supervisor", commune=self.commune_a, is_active=True
        )

        self.agent_a = User.objects.create_user(
            email="agent_a@test.local", password="password", first_name="Ag", last_name="A", role="agent", commune=self.commune_a, is_active=True
        )
        self.agent_b = User.objects.create_user(
            email="agent_b@test.local", password="password", first_name="Ag", last_name="B", role="agent", commune=self.commune_b, is_active=True
        )
        self.citizen = User.objects.create_user(
            email="citizen@test.local", password="password", first_name="C", last_name="Z", role="citizen", is_active=True
        )

        ProfilAgent.objects.create(user=self.agent_a)
        ProfilAgent.objects.create(user=self.agent_b)

        self.dossier_a = Dossier.objects.create(
            commune=self.commune_a, type="naissance", status="in_review", citizen=self.citizen
        )
        self.dossier_b = Dossier.objects.create(
            commune=self.commune_b, type="mariage", status="in_review", citizen=self.citizen
        )

        self.attr_a = AttributionDossier.objects.create(
            dossier=self.dossier_a, agent_actuel=self.agent_a, date_limite_traitement="2026-12-31T23:59:59Z"
        )
        self.attr_b = AttributionDossier.objects.create(
            dossier=self.dossier_b, agent_actuel=self.agent_b, date_limite_traitement="2026-12-31T23:59:59Z"
        )

        self.journal_a = JournalAttribution.objects.create(
            dossier_id=str(self.dossier_a.id), libelle_action="Test A"
        )
        self.journal_b = JournalAttribution.objects.create(
            dossier_id=str(self.dossier_b.id), libelle_action="Test B"
        )

    def test_stats_attribution_scope(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get('/api/attribution/stats/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['total'], 1)

    def test_agents_charge_scope(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get('/api/attribution/agents/charge/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['email'], "agent_a@test.local")

    def test_carte_attribution_scope(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get('/api/attribution/dossiers/carte/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['data']['results']), 1)
        self.assertEqual(response.data['data']['results'][0]['dossier_id'], self.dossier_a.id)

    def test_journal_attribution_scope(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get('/api/attribution/journal/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['data']['results']), 1)
        self.assertEqual(response.data['data']['results'][0]['dossier_id'], str(self.dossier_a.id))

    def test_supervisor_cannot_suspend(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.post('/api/attribution/attribution/suspendre/', {
            'commune_id': self.commune_a.id,
            'duree_heures': 24
        })
        self.assertEqual(response.status_code, 403)

    def tearDown(self):
        self.patcher_celery.stop()
        self.patcher_notif.stop()

    def test_supervisor_cannot_reattribute(self):
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.post(f'/api/attribution/dossier/{self.dossier_a.id}/reattribuer/', {
            'agent_id': self.agent_a.id,
            'raison': 'test'
        })
        self.assertEqual(response.status_code, 403)
