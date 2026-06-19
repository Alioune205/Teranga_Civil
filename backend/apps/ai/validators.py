import hashlib
from apps.dossiers.models import Dossier
from apps.documents.models import Document

def compute_file_hash(file_obj) -> str:
    sha256 = hashlib.sha256()
    for chunk in file_obj.chunks():
        sha256.update(chunk)
    return sha256.hexdigest()

def check_document_duplicate_by_hash(file_obj):
    """
    Vérifie si un document avec le même contenu (hash SHA-256) existe déjà.
    """
    file_hash = compute_file_hash(file_obj)
    
    # Réinitialiser le pointeur du fichier après la lecture du hash
    if hasattr(file_obj, 'seek'):
        file_obj.seek(0)
        
    # Comparaison (Nécessite que Document possède le champ sha256_hash)
    try:
        duplicate = Document.objects.filter(sha256_hash=file_hash).first()
        if duplicate:
            return {
                'is_duplicate': True,
                'document_id': duplicate.id,
                'file_hash': file_hash
            }
    except Exception:
        # Fallback si le champ n'est pas encore migré
        pass

    return {
        'is_duplicate': False,
        'file_hash': file_hash
    }

def validate_citizen_document(citizen_profile, extracted_text):
    """
    Vérifie si les informations du citoyen se trouvent dans le texte extrait.
    Retourne un score de confiance et un dictionnaire des champs trouvés.
    """
    if not extracted_text:
        return {'score': 0, 'details': 'Aucun texte extrait'}

    text_lower = extracted_text.lower()
    score = 0
    max_score = 0
    found_fields = []

    # Vérification du numéro CNI (priorité haute)
    if citizen_profile.cni_number:
        max_score += 50
        # Les espaces peuvent varier dans le texte extrait
        cni_clean = citizen_profile.cni_number.replace(" ", "").lower()
        text_clean = text_lower.replace(" ", "")
        if cni_clean in text_clean:
            score += 50
            found_fields.append('CNI')

    # Vérification de la date de naissance (priorité moyenne)
    if citizen_profile.date_of_birth:
        max_score += 30
        dob_str = citizen_profile.date_of_birth.strftime('%d/%m/%Y')
        dob_str2 = citizen_profile.date_of_birth.strftime('%d-%m-%Y')
        if dob_str in text_lower or dob_str2 in text_lower:
            score += 30
            found_fields.append('Date de Naissance')
            
    # Vérification du nom et prénom (priorité faible/moyenne)
    if citizen_profile.user.last_name:
        max_score += 10
        if citizen_profile.user.last_name.lower() in text_lower:
            score += 10
            found_fields.append('Nom')
            
    if citizen_profile.user.first_name:
        max_score += 10
        if citizen_profile.user.first_name.lower() in text_lower:
            score += 10
            found_fields.append('Prénom')

    confidence_percentage = (score / max_score * 100) if max_score > 0 else 0

    return {
        'score': confidence_percentage,
        'found_fields': found_fields,
        'is_valid': confidence_percentage >= 50  # Seuil de validation arbitraire
    }

def check_dossier_duplicate(citizen, dossier_type):
    """
    Vérifie si le citoyen possède déjà un dossier en cours pour ce même type.
    """
    active_statuses = [
        Dossier.Status.DRAFT,
        Dossier.Status.SUBMITTED,
        Dossier.Status.IN_REVIEW
    ]
    
    duplicate = Dossier.objects.filter(
        citizen=citizen,
        type=dossier_type,
        status__in=active_statuses
    ).first()
    
    if duplicate:
        return {
            'is_duplicate': True,
            'dossier_reference': duplicate.reference,
            'status': duplicate.status
        }
    
    return {
        'is_duplicate': False
    }
