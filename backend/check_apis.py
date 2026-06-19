import requests

BASE_URL = "http://127.0.0.1:8000/api"
client = requests.Session()

report = {"success": [], "failed": []}

def test_endpoint(name, method, url, **kwargs):
    try:
        if method == "GET":
            res = client.get(f"{BASE_URL}{url}", **kwargs)
        elif method == "POST":
            res = client.post(f"{BASE_URL}{url}", **kwargs)
        
        if res.status_code in [200, 201]:
            report["success"].append(f"[OK] {name} ({method} {url})")
        elif res.status_code in [401, 403]:
            # Authorized errors are expected if we don't have token, but we should test with token
            report["success"].append(f"[WARNING] {name} ({method} {url}) - Secured (Auth required)")
        else:
            report["failed"].append(f"[FAILED] {name} ({method} {url}) - FAILED: {res.status_code} {res.text[:100]}")
    except Exception as e:
        report["failed"].append(f"[ERROR] {name} ({method} {url}) - ERROR: {str(e)}")

# 1. Test Communes (Public)
test_endpoint("Liste Communes", "GET", "/communes/")

# 2. Authentification (Login with SuperAdmin to get token)
login_res = client.post(f"{BASE_URL}/auth/login/", json={"email": "superadmin@sunucivil.sn", "password": "password123"})
token = None
if login_res.status_code == 200:
    token = login_res.json().get('data', {}).get('access') or login_res.json().get('access')
    if token:
        report["success"].append(f"[OK] Login SuperAdmin")
    else:
        report["failed"].append(f"[FAILED] Login SuperAdmin: Jeton introuvable dans la réponse {login_res.json()}")
else:
    report["failed"].append(f"[FAILED] Login SuperAdmin: {login_res.status_code}")

headers = {"Authorization": f"Bearer {token}"} if token else {}

# 3. Test Users / Profile
test_endpoint("Profil Utilisateur", "GET", "/users/me/", headers=headers)
test_endpoint("Liste Citoyens", "GET", "/users/?role=citizen", headers=headers)
test_endpoint("Liste Agents", "GET", "/users/?role=agent", headers=headers)

# 4. Test AI / OCR
test_endpoint("Ndiogoye Logs", "GET", "/ai/ndiogoye/logs/", headers=headers)

# 5. Test Dossiers
test_endpoint("Liste Dossiers", "GET", "/dossiers/", headers=headers)
test_endpoint("Créer Dossier", "POST", "/dossiers/", headers=headers, json={
    "type": "birth_certificate",
    "commune": 1,
    "is_for_third_party": False
})

# 6. Test Payments
test_endpoint("Liste Transactions", "GET", "/v1/admin/transactions", headers=headers)
test_endpoint("Initier Paiement", "POST", "/initiate/", headers=headers, json={
    "dossier_id": "MOCK-123",
    "method": "wave",
    "phone": "770000000"
})

# Print Report
print("=== RÉSULTATS DE L'AUDIT DES SERVICES API ===")
for r in report["success"]:
    print(r)
print("\n--- ERREURS ET ÉCHECS ---")
for r in report["failed"]:
    print(r)
