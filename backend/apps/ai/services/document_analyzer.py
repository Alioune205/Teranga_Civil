import logging
import time
from typing import Any, Dict
from apps.ai.services.gemini_client import analyze_document_with_gemini
from apps.ai.services.validation_engine import validate_extracted_data
from apps.ai.services.procedure_engine import get_compatible_procedures

logger = logging.getLogger(__name__)

def analyze_document(file_obj_or_bytes: Any, engine: str = "gemini") -> Dict[str, Any]:
    """
    Couche d'abstraction principale pour l'analyse documentaire.
    Permet de basculer facilement entre Gemini, EasyOCR, DocTR, etc.
    Retourne toujours un dictionnaire normalisé.
    """
    start_time = time.time()
    
    # Init du retour par défaut
    result = {
        "success": False,
        "document_type": "inconnu",
        "confidence": 0.0,
        "raw_text": "",
        "structured_data": {},
        "metadata": {},
        "validation": {},
        "usable_for": [],
        "processing_time": 0.0
    }
    
    try:
        if engine == "gemini":
            logger.info("[OCR] Démarrage de l'analyse avec Gemini Vision.")
            gemini_res = analyze_document_with_gemini(file_obj_or_bytes)
            
            if not gemini_res:
                logger.error("[OCR] Échec de l'analyse Gemini.")
                return result
                
            result["document_type"] = gemini_res.get("document_type", "inconnu")
            result["confidence"] = gemini_res.get("confidence", 0.0)
            result["raw_text"] = gemini_res.get("raw_text", "")
            result["structured_data"] = gemini_res.get("structured_data", {})
            result["metadata"] = gemini_res.get("metadata", {})
            result["success"] = True
            
        elif engine == "easyocr":
            # Future implémentation avec extract_text_from_file + regex (plus basique)
            from apps.ai.ocr import extract_text_from_file, extract_cni_data
            logger.info("[OCR] Démarrage de l'analyse avec EasyOCR.")
            raw_text = extract_text_from_file(file_obj_or_bytes)
            result["raw_text"] = raw_text
            # Basic fallback
            if "carte nationale" in raw_text.lower():
                result["document_type"] = "cni"
                result["structured_data"] = extract_cni_data(file_obj_or_bytes)
            result["success"] = bool(raw_text)
            
        else:
            logger.error(f"[OCR] Moteur non supporté : {engine}")
            return result
            
        # -- Validation & Procedures --
        if result["success"]:
            result["validation"] = validate_extracted_data(result["document_type"], result["structured_data"])
            result["usable_for"] = get_compatible_procedures(result["document_type"])
            logger.info(f"[OCR] Analyse terminée avec succès. Type détecté: {result['document_type']}")
            
            # Logs Audit
            if result["validation"].get("is_valid"):
                logger.info("[OCR] Validation réussie.")
            else:
                logger.warning(f"[OCR] Validation échouée: {result['validation'].get('warnings')}")

    except Exception as e:
        logger.error(f"[OCR] Erreur critique lors de l'analyse : {str(e)}")
        
    finally:
        result["processing_time"] = round(time.time() - start_time, 2)
        
    return result
