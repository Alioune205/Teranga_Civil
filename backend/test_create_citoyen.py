import requests

def test_create_citoyen():
    base_url = 'http://localhost:8000/api'
    
    # 1. Login to get token
    res = requests.post(f"{base_url}/auth/login/", json={
        "email": "superadmin@terangacivil.sn",
        "password": "Password123!"
    })
    
    if res.status_code != 200:
        # If password changed or wrong, try to extract error
        print("Login failed:", res.status_code, res.text)
        return
        
    token = res.json().get('data', {}).get('access')
    if not token:
        print("No token in response:", res.json())
        return
        
    # 2. Get Communes to get a valid commune ID
    headers = {'Authorization': f'Bearer {token}'}
    res_commune = requests.get(f"{base_url}/communes/", headers=headers)
    if res_commune.status_code != 200:
        print("Failed to get communes:", res_commune.text)
        return
        
    communes = res_commune.json().get('data', {}).get('results', [])
    if not communes:
        print("No communes found")
        return
    commune_id = communes[0]['id']
    
    # 3. Create Citoyen
    payload = {
        "prenom": "Alioune",
        "nom": "Sene",
        "date_naissance": "1990-01-01",
        "sexe": "M",
        "nationalite": "Sénégalaise",
        "telephone": "+221775026615",
        "commune": commune_id,
        "adresse": "Cite Socabeg",
        "quartier": "Dakar",
        "email": "senepapealioune@gmail.com"
    }
    
    res_create = requests.post(f"{base_url}/citoyens/", json=payload, headers=headers)
    print("Create status:", res_create.status_code)
    print("Create response:", res_create.text)

if __name__ == '__main__':
    test_create_citoyen()
