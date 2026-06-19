from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch

from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import Dossier

class ManualRoleVerificationTests(APITestCase):

    @patch('apps.etat_civil.signals_attribution.attribuer_dossier_async.delay')
    def setUp(self, mock_delay):
        self.commune, _ = Commune.objects.get_or_create(code="TEST01", defaults={"name": "Commune Test"})
        
        self.super_admin, _ = User.objects.get_or_create(
            email="superadmin@test.local", 
            defaults={"role": "super_admin", "first_name": "Super", "last_name": "Admin", "password": "pass"}
        )
        
        self.supervisor, _ = User.objects.get_or_create(
            email="supervisor@test.local", 
            defaults={"role": "civil_admin_supervisor", "first_name": "Admin", "last_name": "Général", "commune": self.commune, "password": "pass"}
        )
        
        self.civil_admin, _ = User.objects.get_or_create(
            email="civiladmin@test.local", 
            defaults={"role": "civil_admin", "first_name": "RH", "last_name": "Mairie", "commune": self.commune, "password": "pass"}
        )
        
        self.agent_reception, _ = User.objects.get_or_create(
            email="agentrec@test.local", 
            defaults={"role": "agent", "agent_capabilities": ["reception"], "first_name": "Agent", "last_name": "Réception", "commune": self.commune, "password": "pass"}
        )
        
        self.agent_verification, _ = User.objects.get_or_create(
            email="agentverif@test.local", 
            defaults={"role": "agent", "agent_capabilities": ["verification"], "first_name": "Agent", "last_name": "Vérif", "commune": self.commune, "password": "pass"}
        )
        
        self.agent_approval, _ = User.objects.get_or_create(
            email="agentapp@test.local", 
            defaults={"role": "agent", "agent_capabilities": ["approval"], "first_name": "Agent", "last_name": "Approbation", "commune": self.commune, "password": "pass"}
        )
        
        self.citizen, _ = User.objects.get_or_create(
            email="citizen@test.local", 
            defaults={"role": "citizen", "first_name": "Citoyen", "last_name": "Lambda", "commune": self.commune, "password": "pass"}
        )

        self.draft_dossier, _ = Dossier.objects.get_or_create(
            citizen=self.citizen, commune=self.commune, status=Dossier.Status.DRAFT, type=Dossier.Type.BIRTH_CERTIFICATE
        )
        
        self.submitted_dossier, _ = Dossier.objects.get_or_create(
            citizen=self.citizen, commune=self.commune, status=Dossier.Status.SUBMITTED, type=Dossier.Type.DEATH_CERTIFICATE
        )
        
        self.in_review_dossier, _ = Dossier.objects.get_or_create(
            citizen=self.citizen, commune=self.commune, status=Dossier.Status.IN_REVIEW, type=Dossier.Type.MARRIAGE_CERTIFICATE
        )

    def verify_endpoint(self, user, url, method="get", expected_status=None, data=None):
        self.client.force_authenticate(user=user)
        if method == "get":
            response = self.client.get(url)
        else:
            response = self.client.post(url, data, format='json')
            
        result = "PASS" if expected_status is None or response.status_code == expected_status else f"FAIL (Expected {expected_status}, Got {response.status_code})"
        print(f"[{user.role.ljust(22)}] {method.upper()} {url} -> {response.status_code} {result}")
        if expected_status is not None:
            self.assertEqual(response.status_code, expected_status)

    def test_global_stats(self):
        print("\n=== TEST 1: Dashboard Stats Globales (/api/dashboard/stats/global/) ===")
        url_global = reverse('global-stats')
        self.verify_endpoint(self.super_admin, url_global, expected_status=200)
        self.verify_endpoint(self.supervisor, url_global, expected_status=200)
        self.verify_endpoint(self.civil_admin, url_global, expected_status=403)
        self.verify_endpoint(self.agent_reception, url_global, expected_status=403)

    def test_dashboard_workload(self):
        print("\n=== TEST 2: Dashboard Workload (/api/dashboard/workload/) ===")
        url_workload = '/api/dashboard/workload/'
        self.verify_endpoint(self.super_admin, url_workload, expected_status=200)
        self.verify_endpoint(self.supervisor, url_workload, expected_status=200)
        self.verify_endpoint(self.civil_admin, url_workload, expected_status=200)
        self.verify_endpoint(self.agent_reception, url_workload, expected_status=403)

    def test_workflow_assignation(self):
        print("\n=== TEST 3: Workflow - Assignation (Dossier assign) ===")
        url_assign = f"/api/dossiers/{self.draft_dossier.id}/assign/"
        assign_data = {"agent_id": str(self.agent_reception.id)}
        self.verify_endpoint(self.super_admin, url_assign, method="post", data=assign_data, expected_status=200)
        self.verify_endpoint(self.civil_admin, url_assign, method="post", data=assign_data, expected_status=200)
        self.verify_endpoint(self.supervisor, url_assign, method="post", data=assign_data, expected_status=403)
        self.verify_endpoint(self.agent_reception, url_assign, method="post", data=assign_data, expected_status=403)

    def test_workflow_review(self):
        print("\n=== TEST 4: Workflow - Mise en vérification (Dossier review) ===")
        url_review = f"/api/dossiers/{self.submitted_dossier.id}/review/"
        self.verify_endpoint(self.agent_reception, url_review, method="post", expected_status=403)
        self.verify_endpoint(self.agent_verification, url_review, method="post", expected_status=200)

    def test_workflow_approve(self):
        print("\n=== TEST 5: Workflow - Approbation (Dossier approve) ===")
        url_approve = f"/api/dossiers/{self.in_review_dossier.id}/approve/"
        # verification agent = 403
        self.verify_endpoint(self.agent_verification, url_approve, method="post", expected_status=403)
        
        # Check permissions allows it, we just accept 200/400/500 as long as not 403.
        self.client.force_authenticate(user=self.agent_approval)
        response = self.client.post(url_approve, format='json')
        print(f"[{self.agent_approval.role.ljust(22)}] POST {url_approve} -> {response.status_code}")
        self.assertNotEqual(response.status_code, 403)

    def test_verify_registry(self):
        print("\n=== TEST 6: Workflow - Vérification Registre (verify_registry) ===")
        url_verify = reverse('dossier-verify-registry')
        verify_data = {
            "numero_registre": "123",
            "annee_registre": 2023,
            "commune": self.commune.id,
            "type_acte": Dossier.Type.BIRTH_CERTIFICATE
        }
        
        # Test allowed users (must NOT return 403)
        for user in [self.citizen, self.agent_reception, self.civil_admin, self.super_admin]:
            self.client.force_authenticate(user=user)
            response = self.client.post(url_verify, verify_data, format='json')
            print(f"[{user.role.ljust(22)}] POST {url_verify} -> {response.status_code} (Allowed)")
            self.assertNotEqual(response.status_code, 403)
            
        # Test denied users (MUST return 403)
        for user in [self.agent_verification, self.supervisor]:
            self.client.force_authenticate(user=user)
            response = self.client.post(url_verify, verify_data, format='json')
            print(f"[{user.role.ljust(22)}] POST {url_verify} -> {response.status_code} (Denied)")
            self.assertEqual(response.status_code, 403)
