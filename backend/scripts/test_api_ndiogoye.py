import requests
import json
import time

BASE_URL = "http://127.0.0.1:8000/api/ai"

def test_chatbot():
    print("=========================================")
    print("🤖 TEST DU CHATBOT NDIOGOYE (API) 🤖")
    print("=========================================")
    
    endpoint = f"{BASE_URL}/ndiogoye/chat/"
    
    questions = [
        "Bonjour Ndiogoye !",
        "Je dois déclarer la naissance de mon fils, comment faire et combien de temps j'ai ?",
        "Ok merci. Et pour le certificat de résidence, il faut quoi ?",
        "Je voudrais suivre l'état de mon dossier numéro DOS-999999 s'il te plaît."
    ]
    
    chat_history = []
    
    for q in questions:
        print(f"\n🗣️ Vous : {q}")
        payload = {
            "message": q,
            "chat_history": chat_history,
            "conversation_id": "test_session_123"
        }
        
        try:
            # On ajoute un timeout généreux car le LLM peut prendre quelques secondes
            response = requests.post(endpoint, json=payload, timeout=20)
            if response.status_code == 200:
                data = response.json()
                reply = data.get('reply', '')
                intent = data.get('intent', 'N/A')
                action = data.get('action', 'N/A')
                
                print(f"🤖 Ndiogoye : {reply}")
                print(f"   [Intent: {intent} | Action: {action}]")
                
                # Mise à jour de l'historique pour le maintien de contexte
                chat_history.append({"role": "user", "content": q})
                chat_history.append({"role": "assistant", "content": reply})
            else:
                print(f"❌ Erreur API: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"❌ Erreur de connexion: {e}")
            print("Le serveur Django est-il bien lancé sur le port 8000 ?")
            
        time.sleep(1) # Petite pause entre les questions

if __name__ == "__main__":
    test_chatbot()
