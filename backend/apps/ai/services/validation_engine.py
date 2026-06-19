import logging

logger = logging.getLogger(__name__)

# Règles de validation : quels champs sont strictement requis par type de document
VALIDATION_RULES = {
    "acte_naissance": ["nom", "prenom", "date_naissance", "lieu_naissance", "sexe", "centre_etat_civil", "numero_registre"],
    "acte_deces": ["nom_defunt", "date_deces", "lieu_deces", "numero_registre"],
    "acte_mariage": ["epoux", "epouse", "date_mariage", "lieu_mariage", "numero_registre"],
    "certificat_residence": ["nom", "prenom", "adresse", "date_delivrance"],
    "cni": ["nom", "prenom", "numero_cni", "date_naissance", "sexe", "date_expiration"],
}

def validate_extracted_data(document_type: str, extracted_data: dict) -> dict:
    """
    Vérifie la complétude des données extraites en fonction des règles métiers.
    Retourne un dictionnaire contenant is_valid, completeness_score, missing_fields, warnings.
    """
    if document_type not in VALIDATION_RULES:
        # Si on ne connait pas le type, on ne peut pas vraiment valider
        return {
            "is_valid": True,
            "completeness_score": 100,
            "missing_fields": [],
            "warnings": [f"Aucune règle de validation stricte pour le type {document_type}"]
        }

    required_fields = VALIDATION_RULES[document_type]
    missing_fields = []
    
    for field in required_fields:
        val = extracted_data.get(field)
        if not val or str(val).strip() == "":
            missing_fields.append(field)
            
    total = len(required_fields)
    missing_count = len(missing_fields)
    
    if total == 0:
        score = 100
    else:
        score = int(((total - missing_count) / total) * 100)
        
    return {
        "is_valid": missing_count == 0,
        "completeness_score": score,
        "missing_fields": missing_fields,
        "warnings": [f"Le champ obligatoire '{m}' est manquant ou illisible." for m in missing_fields]
    }
