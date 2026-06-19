import requests

def test_api():
    # Login as admin to get token
    login_data = {
        'email': 'admin@terangacivil.sn',
        'password': 'password123'
    }
    r = requests.post('http://localhost:8000/api/users/login/', json=login_data)
    if r.status_code != 200:
        print("Login failed:", r.status_code, r.text)
        return
        
    token = r.json().get('access')
    headers = {'Authorization': f'Bearer {token}'}
    
    # Download PDF of the last dossier
    r_dossiers = requests.get('http://localhost:8000/api/dossiers/', headers=headers)
    dossiers = r_dossiers.json().get('results', [])
    if not dossiers:
        print("No dossiers found")
        return
        
    dossier_id = dossiers[0]['id']
    pdf_url = f'http://localhost:8000/api/dossiers/{dossier_id}/download-pdf/'
    print(f"Fetching PDF: {pdf_url}")
    
    r_pdf = requests.get(pdf_url, headers=headers)
    print("STATUS:", r_pdf.status_code)
    print("CONTENT:", r_pdf.text[:500])
    
if __name__ == '__main__':
    test_api()
