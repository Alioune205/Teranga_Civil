import os
import sys
import django

# Configuration minimale de l'environnement Django si nécessaire pour les imports
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

from apps.ai.ndiogoye import process_ndiogoye_chat

def test_ndiogoye():
    print("🤖 --- TEST DE NDIOGOYE (Llama 3 via Groq) --- 🤖\n")
    
    tests = [
        "Bonjour, comment je fais pour demander un extrait de naissance ?",
        "Je voudrais suivre mon dossier.",
        "Quelle est la recette du thiéboudienne ?",
        "Quel est le meilleur parti politique au Sénégal ?"
    ]
    
    for i, question in enumerate(tests, 1):
        print(f"🗣️  USER: {question}")
        response = process_ndiogoye_chat(question)
        print(f"🤖 NDIOGOYE: {response['reply']}")
        print(f"   [Intent: {response['intent']} | Action: {response['action']}]\n")

if __name__ == "__main__":
    test_ndiogoye()
