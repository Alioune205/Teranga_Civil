"""
Tools (Agents) for Groq LLM Function Calling.
"""
import json
from apps.dossiers.models import Dossier

def get_dossier_status(user, reference):
    """
    Agent BDD: Récupère le statut d'un dossier par sa référence.
    Il assure que l'utilisateur n'accède qu'à SES dossiers s'il est citoyen.
    """
    try:
        # Sécurité : Si l'utilisateur est un citoyen, on filtre sur lui.
        if user.role == 'citizen':
            dossier = Dossier.objects.get(reference=reference, citizen=user)
        else:
            # Sinon, c'est un agent, il peut chercher n'importe quel dossier de sa commune (ou global)
            # Pour l'instant on fait simple
            dossier = Dossier.objects.get(reference=reference)
            
        return json.dumps({
            "reference": dossier.reference,
            "type": dossier.get_type_display(),
            "status": dossier.get_status_display(),
            "submitted_at": str(dossier.submitted_at) if dossier.submitted_at else None,
            "rejection_reason": dossier.rejection_reason if dossier.status == 'rejected' else None
        })
    except Dossier.DoesNotExist:
        return json.dumps({"error": "Dossier introuvable ou vous n'avez pas l'autorisation d'y accéder."})
    except Exception as e:
        return json.dumps({"error": f"Erreur système: {str(e)}"})

# Base de connaissances basique pour l'exemple
FAQ_KNOWLEDGE_BASE = {
    "mariage": "Pour un acte de mariage, veuillez vous munir des copies des pièces d'identité des époux et des témoins, ainsi que du certificat de célébration.",
    "naissance": "Pour obtenir un acte de naissance, vous devez fournir un certificat médical d'accouchement et une pièce d'identité des parents.",
    "deces": "L'acte de décès nécessite le certificat médical de constatation du décès et le livret de famille ou la pièce d'identité du défunt.",
    "delai": "Le délai de traitement habituel des dossiers est de 48 à 72 heures ouvrables.",
    "prix": "Les démarches d'état civil de base sont généralement gratuites, à l'exception des timbres fiscaux nécessaires pour certains actes."
}

def get_procedure(sujet):
    """
    Agent FAQ: Récupère la procédure d'une démarche spécifique.
    """
    sujet_lower = sujet.lower()
    for key, value in FAQ_KNOWLEDGE_BASE.items():
        if key in sujet_lower:
            return json.dumps({"sujet": key, "procedure": value})
            
    return json.dumps({"error": f"Je n'ai pas d'informations précises sur le sujet: {sujet}. Rapprochez-vous de votre mairie."})


# Configuration du schéma JSON (Tool Calling) pour Groq
TOOLS_SCHEMA = [
    {
        "type": "function",
        "function": {
            "name": "get_dossier_status",
            "description": "Récupère le statut actuel d'un dossier administratif via sa référence.",
            "parameters": {
                "type": "object",
                "properties": {
                    "reference": {
                        "type": "string",
                        "description": "La référence unique du dossier (ex: DOS-123456)."
                    }
                },
                "required": ["reference"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_procedure",
            "description": "Récupère les informations et les documents requis pour une procédure spécifique (mariage, naissance, décès, délai, prix).",
            "parameters": {
                "type": "object",
                "properties": {
                    "sujet": {
                        "type": "string",
                        "description": "Le sujet de la demande (ex: 'mariage', 'naissance', 'deces')."
                    }
                },
                "required": ["sujet"]
            }
        }
    }
]
