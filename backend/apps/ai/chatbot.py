"""
Chatbot Orchestrator via Groq API (Agentic RAG+).
"""
import os
import json
from groq import Groq
from django.conf import settings
from .tools import TOOLS_SCHEMA, get_dossier_status, get_procedure

# Initialisation du client Groq
# On récupère la clé depuis les variables d'environnement (settings)
def get_groq_client():
    api_key = getattr(settings, 'GROQ_API_KEY', os.environ.get('GROQ_API_KEY'))
    if not api_key:
        raise ValueError("La clé GROQ_API_KEY n'est pas configurée.")
    return Groq(api_key=api_key)

SYSTEM_PROMPT = """Tu es Ndiogoye, l'assistant administratif intelligent de TERANGA CIVIL (système d'état civil du Sénégal).
Ton rôle est d'aider les citoyens avec leurs démarches et de suivre leurs dossiers.
Tu es poli, professionnel, concis et tu parles français.
RÈGLE D'OR: Ne JAMAIS inventer de statut de dossier ni de documents. Si on te demande des informations spécifiques, utilise TOUJOURS les outils (tools) à ta disposition.
Si tu ne trouves pas la réponse avec les outils, dis simplement que tu ne sais pas et conseille de se rapprocher de la mairie.

IMPORTANT: Tu dois TOUJOURS formater ta réponse finale (lorsque tu t'adresses à l'utilisateur) UNIQUEMENT sous forme d'un objet JSON valide contenant 3 clés :
- "intent": l'intention détectée ("salutation", "creer_dossier", "suivre_dossier", "info_procedure", ou "inconnu").
- "action": l'action à déclencher côté frontend ("none", "start_dossier", "check_status").
- "reply": ton message texte en français pour le citoyen.
N'ajoute aucun texte avant ou après l'objet JSON. Réponds UNIQUEMENT avec le JSON."""

def chat_orchestrator(user, user_message, chat_history=None):
    """
    Orchestre la discussion avec l'utilisateur, et décide s'il faut appeler un sous-agent.
    """
    if chat_history is None:
        chat_history = []
        
    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + chat_history
    messages.append({"role": "user", "content": user_message})
    
    try:
        client = get_groq_client()
        # Modèle rapide et intelligent pour le Tool Calling
        model_name = "llama-3.3-70b-versatile"
        
        # 1. Premier appel à Groq avec les outils disponibles
        response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            tools=TOOLS_SCHEMA,
            tool_choice="auto",
        )
        
        response_message = response.choices[0].message
        tool_calls = response_message.tool_calls
        
        final_content = response_message.content
        
        # 2. Si Groq décide d'appeler un outil (Agent BDD ou Agent FAQ)
        if tool_calls:
            # On ajoute la réponse de l'assistant (avec l'appel d'outil) à l'historique
            messages.append(response_message)
            
            for tool_call in tool_calls:
                function_name = tool_call.function.name
                function_args = json.loads(tool_call.function.arguments)
                
                # Exécution du bon outil
                if function_name == "get_dossier_status":
                    tool_response = get_dossier_status(
                        user=user,
                        reference=function_args.get("reference")
                    )
                elif function_name == "get_procedure":
                    tool_response = get_procedure(
                        sujet=function_args.get("sujet")
                    )
                else:
                    tool_response = json.dumps({"error": "Outil inconnu"})
                    
                # 3. Ajout du résultat de l'outil à la conversation
                messages.append(
                    {
                        "tool_call_id": tool_call.id,
                        "role": "tool",
                        "name": function_name,
                        "content": tool_response,
                    }
                )
                
            # 4. Deuxième appel à Groq pour générer la réponse finale avec les données récupérées
            second_response = client.chat.completions.create(
                model=model_name,
                messages=messages,
                response_format={"type": "json_object"}
            )
            final_content = second_response.choices[0].message.content
            
        # Si aucun outil n'est appelé, on retourne la réponse directe parsée
        try:
            # Parfois le LLM rajoute des backticks markdown (```json ... ```)
            clean_content = final_content.strip()
            if clean_content.startswith('```json'):
                clean_content = clean_content[7:]
            if clean_content.endswith('```'):
                clean_content = clean_content[:-3]
            clean_content = clean_content.strip()
            
            return json.loads(clean_content)
        except (json.JSONDecodeError, TypeError, AttributeError):
            return {
                "intent": "inconnu",
                "action": "none",
                "reply": final_content or "Désolé, je n'ai pas pu générer une réponse valide."
            }
        
    except Exception as e:
        return {
            "intent": "erreur",
            "action": "none",
            "reply": f"Désolé, j'ai rencontré une erreur lors de la réflexion: {str(e)}"
        }
