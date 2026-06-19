from django.test import TestCase
from rest_framework.test import APIClient
from apps.users.models import User
from apps.communes.models import Commune

class UserScopeTests(TestCase):
    def setUp(self):
        from unittest.mock import patch
        self.patcher = patch('apps.notifications.services.FCMService.send_notification_to_user')
        self.mock_notify = self.patcher.start()

        self.client = APIClient()
        self.commune_a = Commune.objects.create(name="Commune Test A", code="TEST_CA_999", region="Dakar")
        self.commune_b = Commune.objects.create(name="Commune Test B", code="TEST_CB_999", region="Thies")

        self.super_admin = User.objects.create_user(
            email="super@test.local", password="password", first_name="Super", last_name="Admin", role="super_admin", is_active=True
        )

        self.civil_admin = User.objects.create_user(
            email="civil@test.local", password="password", first_name="Civil", last_name="Admin", role="civil_admin", commune=self.commune_a, is_active=True
        )
        
        self.supervisor = User.objects.create_user(
            email="supervisor@test.local", password="password", first_name="Super", last_name="Visor", role="civil_admin_supervisor", commune=self.commune_a, is_active=True
        )

        self.agent_a = User.objects.create_user(
            email="agent_a@test.local", password="password", first_name="Agent", last_name="A", role="agent", commune=self.commune_a, is_active=True
        )
        
        self.agent_b = User.objects.create_user(
            email="agent_b@test.local", password="password", first_name="Agent", last_name="B", role="agent", commune=self.commune_b, is_active=True
        )

    def test_super_admin_can_see_all_users(self):
        self.client.force_authenticate(user=self.super_admin)
        response = self.client.get('/api/users/')
        self.assertEqual(response.status_code, 200)
        emails = [u['email'] for u in response.data['data']['results']]
        self.assertIn('agent_a@test.local', emails)
        self.assertIn('agent_b@test.local', emails)

    def test_civil_admin_can_only_see_commune_users(self):
        self.client.force_authenticate(user=self.civil_admin)
        response = self.client.get('/api/users/')
        self.assertEqual(response.status_code, 200)
        emails = [u['email'] for u in response.data['data']['results']]
        self.assertIn('agent_a@test.local', emails)
        self.assertNotIn('agent_b@test.local', emails)

    def test_supervisor_can_only_see_commune_users(self):
        self.client.force_authenticate(user=self.supervisor)
        response = self.client.get('/api/users/')
        self.assertEqual(response.status_code, 200)
        emails = [u['email'] for u in response.data['data']['results']]
        self.assertIn('agent_a@test.local', emails)
        self.assertNotIn('agent_b@test.local', emails)

    def test_supervisor_cannot_create_user(self):
        self.client.force_authenticate(user=self.supervisor)
        response = self.client.post('/api/users/', {
            'email': 'new@test.local',
            'password': 'password',
            'role': 'agent',
            'commune': self.commune_a.id,
            'first_name': 'New',
            'last_name': 'Agent'
        })
        self.assertEqual(response.status_code, 403)

    def test_civil_admin_can_create_user(self):
        self.client.force_authenticate(user=self.civil_admin)
        response = self.client.post('/api/users/', {
            'email': 'new2@test.local',
            'password': 'password',
            'role': 'agent',
            'agent_capabilities': ['reception'],
            'commune': self.commune_a.id,
            'first_name': 'New2',
            'last_name': 'Agent2'
        })
        self.assertEqual(response.status_code, 201)

    def tearDown(self):
        self.patcher.stop()
