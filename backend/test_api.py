import requests

def test_api():
    base_url = 'http://localhost:8000/api'
    # 1. Login
    res = requests.post(f"{base_url}/auth/login/", json={
        "email": "admin@terangacivil.sn",
        "password": "Teranga2026!"
    })
    
    if res.status_code != 200:
        print("Login failed:", res.status_code, res.text)
        return
        
    token = res.json().get('data', {}).get('access')
    if not token:
        print("No token in response:", res.json())
        return
        
    # 2. Get Citoyens
    headers = {'Authorization': f'Bearer {token}'}
    res = requests.get(f"{base_url}/citoyens/", headers=headers)
    print("Citoyens status:", res.status_code)
    print("Citoyens response:", res.text)

if __name__ == '__main__':
    test_api()
