# apps/ai/services/procedure_engine.py

PROCEDURES_REQUIREMENTS = {
    "declaration_naissance": ["certificat_accouchement", "cni_pere", "cni_mere"],
    "certificat_vie": ["acte_naissance", "cni"],
    "prise_en_charge_familiale": ["acte_naissance", "cni", "certificat_residence"],
    "declaration_mariage": ["acte_naissance", "cni_epoux", "cni_epouse", "certificat_celibat"],
    "declaration_deces": ["certificat_genre_mort", "cni_defunt", "cni_declarant"]
}

DOCUMENT_TO_PROCEDURES = {
    "acte_naissance": ["declaration_naissance", "certificat_vie", "prise_en_charge_familiale", "declaration_mariage", "cni"],
    "cni": ["certificat_vie", "prise_en_charge_familiale", "declaration_mariage", "declaration_deces"],
    "certificat_accouchement": ["declaration_naissance"],
    "certificat_residence": ["prise_en_charge_familiale"],
    "certificat_celibat": ["declaration_mariage"],
    "certificat_genre_mort": ["declaration_deces"],
}

def get_compatible_procedures(document_type: str) -> list:
    """Retourne la liste des démarches compatibles avec un type de document."""
    return DOCUMENT_TO_PROCEDURES.get(document_type, [])

def check_missing_documents(procedure_name: str, detected_documents: list) -> dict:
    """Vérifie les pièces manquantes pour une démarche spécifique."""
    if procedure_name not in PROCEDURES_REQUIREMENTS:
        return {"error": f"Procédure inconnue : {procedure_name}"}

    required_docs = PROCEDURES_REQUIREMENTS[procedure_name]
    # Simple check for now: assuming detected_documents is a list of doc types e.g. ["certificat_accouchement", "cni_pere"]
    missing_docs = [doc for doc in required_docs if doc not in detected_documents]
    
    total = len(required_docs)
    found = total - len(missing_docs)
    completude = int((found / total) * 100) if total > 0 else 100
    
    return {
        "procedure": procedure_name,
        "documents_detectes": detected_documents,
        "documents_manquants": missing_docs,
        "completude": completude
    }
