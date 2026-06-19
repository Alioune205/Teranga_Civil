import uuid
import logging
from groq import Groq
from decouple import config
from .faq import find_closest_faq

logger = logging.getLogger(__name__)

# Initialisation du client Groq.
client = None
try:
    api_key = config("GROQ_API_KEY", default=None)
    if api_key:
        client = Groq(api_key=api_key)
    else:
        logger.warning("GROQ_API_KEY non trouvée dans le fichier .env")
except Exception as e:
    logger.error(f"Erreur d'initialisation de Groq : {e}")


def process_ndiogoye_chat(message: str, conversation_id: str = None) -> dict:
    if not conversation_id:
        conversation_id = str(uuid.uuid4())
        
    intent = "inconnu"
    action = "none"
    
    # ── ÉTAPE 1: FAQ-First (Recherche dans la base validée avec RapidFuzz) ──
    faq_answer = find_closest_faq(message, threshold=65.0)
    
    # Déduction simple d'intention pour guider le Frontend
    message_lower = message.lower()
    if any(word in message_lower for word in ["créer", "creer", "demande", "nouveau"]):
        intent = "creer_dossier"
        action = "start_dossier"
    elif any(word in message_lower for word in ["suivre", "statut", "état", "etat"]):
        intent = "suivre_dossier"
        action = "check_status"

    # Si c'est le message de fallback (score < 80%), on stoppe ici et on répond strictement.
    # Aucune génération libre autorisée en dehors du périmètre.
    if faq_answer == "Je ne dispose pas de cette information. Veuillez consulter un agent d'état civil.":
        return {
            "reply": faq_answer,
            "action": action,
            "intent": intent,
            "conversation_id": conversation_id
        }

    # ── ÉTAPE 2: Reformulation IA (Optionnelle et strictement encadrée) ──
    # Si on a trouvé une réponse validée dans la FAQ, on utilise le LLM 
    # UNIQUEMENT pour la reformuler de façon naturelle, sans rien inventer.
    reply = faq_answer
    
    if client:
        try:
            system_prompt = (
                "Tu es Ndiogoye, l'assistant virtuel de TERANGA CIVIL (plateforme d'état civil du Sénégal). "
                "Ton rôle STRICT est de TRADUIRE et reformuler de manière polie et conviviale une réponse administrative validée en WOLOF (la langue locale du Sénégal). "
                "RÈGLES ABSOLUES: "
                "1. Ta réponse finale DOIT être EXCLUSIVEMENT en WOLOF (sauf termes administratifs officiels). "
                "2. N'INVENTE AUCUNE information supplémentaire, procédure, document ou frais. "
                "3. Base-toi EXCLUSIVEMENT sur le texte fourni dans 'Réponse FAQ'. "
                "4. Ne réponds jamais à une question par tes propres connaissances. "
                "5. Sois court et chaleureux. "
                f"\n\nRéponse FAQ stricte à utiliser : {faq_answer}"
            )
            
            chat_completion = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Voici ma question : '{message}'. Traduis et reformule la réponse FAQ de manière naturelle EN WOLOF."}
                ],
                model="llama-3.3-70b-versatile",
                temperature=0.2,
                max_tokens=250,
            )
            
            reply = chat_completion.choices[0].message.content
                
        except Exception as e:
            logger.error(f"Erreur lors de l'appel à l'API Groq: {e}")
            # Fallback sécurisé: on renvoie la FAQ brute si l'IA plante
            reply = faq_answer

    return {
        "reply": reply,
        "action": action,
        "intent": intent,
        "conversation_id": conversation_id
    }
