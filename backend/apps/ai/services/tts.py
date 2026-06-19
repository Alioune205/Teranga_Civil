import os
import requests
import base64
import logging
from django.conf import settings

logger = logging.getLogger("apps")

def generate_wolof_audio_base64(text: str) -> str:
    """
    Appelle l'API ElevenLabs pour générer de l'audio en langue locale (Wolof phonétique)
    à partir d'un texte.
    Retourne l'audio généré encodé en base64 (mp3).
    """
    api_key = getattr(settings, "ELEVENLABS_API_KEY", os.environ.get("ELEVENLABS_API_KEY"))
    if not api_key:
        logger.error("ELEVENLABS_API_KEY manquante.")
        return None

    # Utilisation du modèle Multilingual V2 qui gère mieux les accents africains
    # L'ID de voix '21m00Tcm4TlvDq8ikWAM' correspond à Rachel (voix féminine) ou un autre ID personnalisé
    # Pour le Wolof/Hackathon, on utilise une voix générique claire, par exemple 'EXAVITQu4vr4xnSDxMaL' (Bella)
    voice_id = "EXAVITQu4vr4xnSDxMaL"
    
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"

    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key
    }

    data = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75
        }
    }

    try:
        response = requests.post(url, json=data, headers=headers)
        response.raise_for_status()
        
        audio_bytes = response.content
        audio_b64 = base64.b64encode(audio_bytes).decode('utf-8')
        logger.info(f"Audio TTS généré avec succès ({len(audio_b64)} caractères base64).")
        return audio_b64
    except Exception as e:
        logger.error(f"Erreur lors de la génération TTS ElevenLabs: {e}")
        return None
