import requests
import re
base_url = 'http://localhost:8000/api'
res = requests.post(f'{base_url}/auth/login/', json={'email': 'admin@terangacivil.sn', 'password': 'Teranga2026!'})
token = res.json().get('data', {}).get('access')
res = requests.get(f'{base_url}/dossiers/', headers={'Authorization': f'Bearer {token}'})

text = res.text
matches = re.search(r'<textarea id="traceback_area".*?>(.*?)</textarea>', text, re.DOTALL)
if matches:
    print(matches.group(1))
else:
    print("No traceback found. First 500 chars:", text[:500])
