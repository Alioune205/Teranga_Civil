import logging

logger = logging.getLogger(__name__)

def accord(genre, masculin, feminin, dossier_id="inconnu"):
    """
    Retourne la forme masculine ou féminine d'un mot selon le genre.
    Si le genre est absent, utilise le masculin par défaut et log un warning.
    """
    if not genre:
        logger.warning(f"Genre non renseigné pour dossier {dossier_id}, masculin utilisé par défaut")
        return masculin
        
    genre = str(genre).strip().upper()
    if genre in ('F', 'FEMININ', 'FEMME'):
        return feminin
    return masculin
