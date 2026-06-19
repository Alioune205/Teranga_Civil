from rest_framework.test import APITestCase
from django.urls import reverse
from rest_framework import status
from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.audit_logs.models import AuditLog

class AuditLogScopeTests(APITestCase):
    def setUp(self):
        self.commune_a = Commune.objects.create(name="Commune A", code="CMA")
        self.commune_b = Commune.objects.create(name="Commune B", code="CMB")

        self.super_admin = User.objects.create_user(email="super@test.com", password="pass", role="super_admin")
        self.supervisor_a = User.objects.create_user(email="sup_a@test.com", password="pass", role="civil_admin_supervisor", commune=self.commune_a)
        self.supervisor_b = User.objects.create_user(email="sup_b@test.com", password="pass", role="civil_admin_supervisor", commune=self.commune_b)
        self.civil_admin = User.objects.create_user(email="rh@test.com", password="pass", role="civil_admin", commune=self.commune_a)
        
        self.agent_a = User.objects.create_user(email="agent_a@test.com", password="pass", role="agent", commune=self.commune_a)
        self.agent_b = User.objects.create_user(email="agent_b@test.com", password="pass", role="agent", commune=self.commune_b)

        self.dossier_a = Dossier.objects.create(commune=self.commune_a)
        self.dossier_b = Dossier.objects.create(commune=self.commune_b)

        # Log de l'agent A (lié à la commune A via user__commune)
        AuditLog.log(user=self.agent_a, action=AuditLog.Action.LOGIN, resource_type="auth")
        
        # Log sur un dossier de la commune A (lié via resource_id) fait par le système
        AuditLog.log(user=None, user_type=AuditLog.UserType.SYSTEM, action=AuditLog.Action.CREATE, resource_type="dossier", resource_id=self.dossier_a.id)

        # Log sur un agent de la commune A (lié via resource_id) fait par le système
        AuditLog.log(user=None, user_type=AuditLog.UserType.SYSTEM, action=AuditLog.Action.UPDATE, resource_type="user", resource_id=self.agent_a.id)

        # Logs pour la commune B
        AuditLog.log(user=self.agent_b, action=AuditLog.Action.LOGIN, resource_type="auth")
        AuditLog.log(user=None, user_type=AuditLog.UserType.SYSTEM, action=AuditLog.Action.CREATE, resource_type="dossier", resource_id=self.dossier_b.id)

        self.url = reverse('auditlog-list')

    def test_civil_admin_forbidden(self):
        """Un civil_admin classique n'a pas accès aux logs d'audit"""
        self.client.force_authenticate(user=self.civil_admin)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_super_admin_sees_all(self):
        """Le super admin voit tous les logs"""
        self.client.force_authenticate(user=self.super_admin)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data.get('data', {})
        results = data.get('results', data) if isinstance(data, dict) else data
        self.assertTrue(len(results) > 0)

    def test_supervisor_sees_only_own_commune(self):
        """Le superviseur ne voit que les logs de sa commune (user ou resource)"""
        self.client.force_authenticate(user=self.supervisor_a)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Le superviseur A devrait voir les 3 logs liés à la commune A (agent_a login, dossier_a create, agent_a update)
        data_a = response.data.get('data', {})
        results_a = data_a.get('results', data_a) if isinstance(data_a, dict) else data_a
        self.assertTrue(len(results_a) > 0)
        
        # Vérifions les resource_type remontés
        resource_types = [log['resource_type'] for log in results_a]
        self.assertIn('auth', resource_types)
        self.assertIn('dossier', resource_types)
        self.assertIn('user', resource_types)

        # Test superviseur B
        self.client.force_authenticate(user=self.supervisor_b)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data_b = response.data.get('data', {})
        results_b = data_b.get('results', data_b) if isinstance(data_b, dict) else data_b
        self.assertTrue(len(results_b) > 0)
        
        # S'assurer que le superviseur B ne voit pas les logs du superviseur A
        b_emails = [log['user_email'] for log in results_b if log['user_email']]
        self.assertNotIn('agent_a@test.com', b_emails)
