"""
Module FAQ utilisant RapidFuzz pour l'architecture FAQ-First.
"""
from rapidfuzz import process, fuzz

# Base de connaissances: chaque entrée possède une liste de questions courantes 
# et LA réponse stricte validée par l'administration.
FAQ_BASE = [
    {
        "questions": [
            "comment obtenir un extrait de naissance ?",
            "pièces pour acte de naissance",
            "comment faire un acte de naissance",
            "déclarer une naissance",
            "je veux un extrait de naissance"
        ],
        "answer": "Pour obtenir un acte de naissance, vous devez fournir un certificat médical d'accouchement et une pièce d'identité des parents."
    },
    {
        "questions": [
            "comment obtenir un acte de mariage ?",
            "pièces pour acte de mariage",
            "documents pour se marier",
            "je veux faire un mariage"
        ],
        "answer": "Pour un acte de mariage, veuillez vous munir des copies des pièces d'identité des époux et des témoins, ainsi que du certificat de célébration."
    },
    {
        "questions": [
            "comment déclarer un décès ?",
            "pièces pour acte de décès",
            "documents pour décès",
            "obtenir un acte de décès"
        ],
        "answer": "L'acte de décès nécessite le certificat médical de constatation du décès et le livret de famille ou la pièce d'identité du défunt."
    },
    {
        "questions": [
            "comment avoir un certificat de résidence ?",
            "certificat de domicile",
            "preuve de résidence"
        ],
        "answer": "Pour le certificat de résidence, un justificatif de domicile (facture SENELEC/SEN'EAU) récent est requis."
    },
    {
        "questions": [
            "quel est le délai de traitement ?",
            "combien de temps ça prend ?",
            "durée pour avoir un document",
            "quand mon acte sera prêt ?"
        ],
        "answer": "Le délai de traitement habituel des dossiers est de 48 à 72 heures ouvrables."
    },
    {
        "questions": [
            "quel est le prix ?",
            "combien ça coûte ?",
            "frais pour un acte",
            "tarif des documents",
            "faut-il payer ?"
        ],
        "answer": "Les démarches d'état civil de base sont généralement gratuites, à l'exception des timbres fiscaux nécessaires pour certains actes."
    },
    {
        "questions": [
            "il y a une erreur sur mon acte",
            "comment modifier un document ?",
            "rectification d'erreur matérielle",
            "changer mon nom sur l'acte"
        ],
        "answer": "En cas d'erreur sur un acte, il faut entamer une procédure de jugement d'hérédité ou de rectification au niveau du tribunal d'instance."
    },
    {
        "questions": [
            "bonjour",
            "salut",
            "hello",
            "coucou",
            "bonsoir"
        ],
        "answer": "Bonjour ! Je suis Ndiogoye, l'assistant IA de TERANGA CIVIL. Posez-moi votre question concernant vos démarches."
    }
]

# Aplatir la structure pour RapidFuzz : { "question": "réponse" }
FLAT_FAQ = {}
for item in FAQ_BASE:
    for q in item["questions"]:
        FLAT_FAQ[q] = item["answer"]

def find_closest_faq(user_message: str, threshold: float = 65.0) -> str:
    """
    Trouve la réponse FAQ la plus pertinente via Fuzzy Matching.
    Si le score < threshold (70%), retourne une réponse stricte de fallback.
    """
    user_message = user_message.lower().strip()
    
    # process.extractOne retourne un tuple : (matched_string, score, index_key)
    result = process.extractOne(
        user_message,
        FLAT_FAQ.keys(),
        scorer=fuzz.token_set_ratio
    )
    
    if result:
        matched_str, score, _ = result
        if score >= threshold:
            return FLAT_FAQ[matched_str]
            
    return "Je ne dispose pas de cette information. Veuillez consulter un agent d'état civil."
