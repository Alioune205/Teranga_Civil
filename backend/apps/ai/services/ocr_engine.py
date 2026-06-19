import logging
from apps.ai.ocr import extract_text_from_file, extract_text_from_base64

logger = logging.getLogger(__name__)

def extract_text(file_obj) -> dict:
    """
    Couche d'abstraction OCR.
    Pour l'instant, utilise EasyOCR (via apps.ai.ocr.extract_text_from_file).
    Prêt pour une migration vers DocTR ou PaddleOCR.
    """
    try:
        raw_text = extract_text_from_file(file_obj)
        return {
            "raw_text": raw_text,
            "confidence": 0.85, # Valeur factice en attendant DocTR
            "engine": "easyocr_legacy"
        }
    except Exception as e:
        logger.error(f"Erreur extraction OCR abstraite : {e}")
        return {
            "raw_text": "",
            "confidence": 0.0,
            "engine": "error"
        }

def extract_text_base64(base64_string: str) -> dict:
    """
    Couche d'abstraction OCR pour base64.
    """
    try:
        raw_text = extract_text_from_base64(base64_string)
        return {
            "raw_text": raw_text,
            "confidence": 0.85,
            "engine": "easyocr_legacy"
        }
    except Exception as e:
        logger.error(f"Erreur extraction OCR abstraite (base64) : {e}")
        return {
            "raw_text": "",
            "confidence": 0.0,
            "engine": "error"
        }
