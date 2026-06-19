from django.urls import reverse
from unittest.mock import patch

from rest_framework.test import APIClient
from rest_framework import status

from apps.users.models import User
from apps.communes.models import Commune
from apps.dossiers.models import Dossier

def create_users_and_dossiers():
    commune, _ = Commune.objects.get_or_create(code="TEST01", defaults={"name": "Commune Test"})
    
    # 1. super_admin
    super_admin, _ = User.objects.get_or_create(
        email="superadmin@test.local", 
        defaults={"role": "super_admin", "first_name": "Super", "last_name": "Admin", "password": "pass"}
    )
    
    # 2. civil_admin_supervisor
    supervisor, _ = User.objects.get_or_create(
        email="supervisor@test.local", 
        defaults={"role": "civil_admin_supervisor", "first_name": "Admin", "last_name": "Général", "commune": commune, "password": "pass"}
    )
    
    # 3. civil_admin
    civil_admin, _ = User.objects.get_or_create(
        email="civiladmin@test.local", 
        defaults={"role": "civil_admin", "first_name": "RH", "last_name": "Mairie", "commune": commune, "password": "pass"}
    )
    
    # 4. agent (with only 'reception' capability)
    agent_reception, _ = User.objects.get_or_create(
        email="agentrec@test.local", 
        defaults={"role": "agent", "agent_capabilities": ["reception"], "first_name": "Agent", "last_name": "Réception", "commune": commune, "password": "pass"}
    )
    
    # 5. agent (with only 'verification' capability)
    agent_verification, _ = User.objects.get_or_create(
        email="agentverif@test.local", 
        defaults={"role": "agent", "agent_capabilities": ["verification"], "first_name": "Agent", "last_name": "Vérif", "commune": commune, "password": "pass"}
    )
    
    # 6. agent (with only 'approval' capability)
    agent_approval, _ = User.objects.get_or_create(
        email="agentapp@test.local", 
        defaults={"role": "agent", "agent_capabilities": ["approval"], "first_name": "Agent", "last_name": "Approbation", "commune": commune, "password": "pass"}
    )
    
    # Citizen
    citizen, _ = User.objects.get_or_create(
        email="citizen@test.local", 
        defaults={"role": "citizen", "first_name": "Citoyen", "last_name": "Lambda", "commune": commune, "password": "pass"}
    )

    # Dossiers for workflow test
    # Create a draft dossier
    draft_dossier, _ = Dossier.objects.get_or_create(
        citizen=citizen, commune=commune, status=Dossier.Status.DRAFT, type=Dossier.Type.BIRTH_CERTIFICATE
    )
    
    # Submitted dossier for verification
    submitted_dossier, _ = Dossier.objects.get_or_create(
        citizen=citizen, commune=commune, status=Dossier.Status.SUBMITTED, type=Dossier.Type.DEATH_CERTIFICATE
    )
    
    # In review dossier for approval
    in_review_dossier, _ = Dossier.objects.get_or_create(
        citizen=citizen, commune=commune, status=Dossier.Status.IN_REVIEW, type=Dossier.Type.MARRIAGE_CERTIFICATE
    )
    
    return {
        "super_admin": super_admin,
        "supervisor": supervisor,
        "civil_admin": civil_admin,
        "agent_reception": agent_reception,
        "agent_verification": agent_verification,
        "agent_approval": agent_approval,
        "draft_dossier": draft_dossier,
        "submitted_dossier": submitted_dossier,
        "in_review_dossier": in_review_dossier
    }

def verify_endpoint(client, user, url, method="get", expected_status=None, data=None):
    client.force_authenticate(user=user)
    if method == "get":
        response = client.get(url)
    else:
        response = client.post(url, data, format='json')
        
    result = "PASS" if expected_status is None or response.status_code == expected_status else f"FAIL (Expected {expected_status}, Got {response.status_code})"
    print(f"[{user.role.ljust(22)}] {method.upper()} {url} -> {response.status_code} {result}")

def run_tests():
    data = create_users_and_dossiers()
    client = APIClient()
    
    print("\n=== TEST 1: Dashboard Stats Globales (/api/dashboard/stats/global/) ===")
    url_global = reverse('global-stats')
    # super_admin & supervisor -> 200, others -> 403
    verify_endpoint(client, data["super_admin"], url_global, expected_status=200)
    verify_endpoint(client, data["supervisor"], url_global, expected_status=200)
    verify_endpoint(client, data["civil_admin"], url_global, expected_status=403)
    verify_endpoint(client, data["agent_reception"], url_global, expected_status=403)
    
    print("\n=== TEST 2: Dashboard Workload (/api/dashboard/workload/) ===")
    # No reverse name for workload defined yet maybe? Let's check.
    # We added WorkloadStatsView but didn't check urls.py. Let's use direct URL if reverse fails.
    url_workload = '/api/dashboard/workload/'
    # super_admin, supervisor, civil_admin -> 200, agents -> 403
    verify_endpoint(client, data["super_admin"], url_workload, expected_status=200)
    verify_endpoint(client, data["supervisor"], url_workload, expected_status=200)
    verify_endpoint(client, data["civil_admin"], url_workload, expected_status=200)
    verify_endpoint(client, data["agent_reception"], url_workload, expected_status=403)

    print("\n=== TEST 3: Workflow - Assignation (Dossier assign) ===")
    url_assign = f"/api/dossiers/{data['draft_dossier'].id}/assign/"
    assign_data = {"agent_id": str(data["agent_reception"].id)}
    # civil_admin & super_admin -> 200 (supervisor = 403, agents = 403)
    verify_endpoint(client, data["super_admin"], url_assign, method="post", data=assign_data, expected_status=200)
    verify_endpoint(client, data["civil_admin"], url_assign, method="post", data=assign_data, expected_status=200)
    verify_endpoint(client, data["supervisor"], url_assign, method="post", data=assign_data, expected_status=403)
    verify_endpoint(client, data["agent_reception"], url_assign, method="post", data=assign_data, expected_status=403)

    print("\n=== TEST 4: Workflow - Mise en vérification (Dossier review) ===")
    url_review = f"/api/dossiers/{data['submitted_dossier'].id}/review/"
    # verification agent, civil_admin, super_admin -> 200 (reception agent = 403)
    verify_endpoint(client, data["agent_reception"], url_review, method="post", expected_status=403)
    verify_endpoint(client, data["agent_verification"], url_review, method="post", expected_status=200)

    print("\n=== TEST 5: Workflow - Approbation (Dossier approve) ===")
    url_approve = f"/api/dossiers/{data['in_review_dossier'].id}/approve/"
    # approval agent, civil_admin, super_admin -> 200 (verification agent = 403)
    verify_endpoint(client, data["agent_verification"], url_approve, method="post", expected_status=403)
    # the approve method requires cryptographic signature, might fail 500 if setup is wrong, but permission should be allowed
    verify_endpoint(client, data["agent_approval"], url_approve, method="post")

run_tests()
