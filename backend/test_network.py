import requests
import sys

# Login to get the token
login_url = "http://127.0.0.1:8000/api/auth/login/"
try:
    response = requests.post(login_url, json={
        "email": "superadmin@test.local",
        "password": "pass"
    })
    response.raise_for_status()
    token = response.json().get("access")
except Exception as e:
    print(f"Login failed: {e}")
    sys.exit(1)

# Make the AI request
ai_url = "http://127.0.0.1:8000/api/ai/admin-assistant/"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}
payload = {
    "question": "Salut",
    "chat_history": [
        {"role": "assistant", "content": "Bonjour Super, je suis votre Assistant Analytique Teranga Civil. Je peux analyser les statistiques de votre commune (ou globales). Posez-moi une question !"},
        {"role": "user", "content": "Salut"}
    ]
}

try:
    response = requests.post(ai_url, json=payload, headers=headers)
    print("STATUS:", response.status_code)
    print("BODY:", response.text)
except Exception as e:
    print(f"AI request failed: {e}")
