"""
Module OCR unifié — EasyOCR + support PDF via pypdfium2.

Sources acceptées :
  1. Image uploadée  (JPG, PNG, WEBP, BMP...)
  2. PDF uploadé     (toutes les pages sont analysées)
  3. Image base64    (capture caméra WebRTC depuis le frontend)
"""
import logging
import os
import re
import io
import base64
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────
# Initialisation EasyOCR (une seule fois)
# ─────────────────────────────────────────────
ocr_model = None
try:
    import easyocr
    ocr_model = easyocr.Reader(['fr', 'en'], gpu=False)
    logger.info("EasyOCR initialisé avec succès.")
except Exception as e:
    ocr_model = None
    logger.error(f"EasyOCR n'a pas pu être initialisé : {e}")


# ─────────────────────────────────────────────
# Utilitaires internes
# ─────────────────────────────────────────────

def preprocess_image(image: Image.Image) -> Image.Image:
    """Améliore la qualité de l'image avant l'OCR."""
    image = image.convert('L')
    image = image.filter(ImageFilter.SHARPEN)
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)
    return image


def _run_ocr_on_pil(image: Image.Image) -> str:
    """Lance EasyOCR sur une image PIL et retourne le texte extrait."""
    if not ocr_model:
        return ""
    image = preprocess_image(image)
    image = image.convert('RGB')
    image_np = np.array(image)
    result = ocr_model.readtext(image_np)
    return "\n".join(text for (_, text, conf) in result if conf > 0.2)


def _is_pdf(file_obj) -> bool:
    """Détecte si un fichier est un PDF en lisant ses 4 premiers octets."""
    try:
        header = file_obj.read(4)
        file_obj.seek(0)
        return header == b'%PDF'
    except Exception:
        return False


def _extract_text_from_pdf(file_obj) -> str:
    """
    Extrait le texte de toutes les pages d'un PDF via pypdfium2 + EasyOCR.
    Chaque page est rendue en image haute résolution, puis analysée par OCR.
    """
    try:
        import pypdfium2 as pdfium
        pdf_bytes = file_obj.read()
        pdf = pdfium.PdfDocument(pdf_bytes)
        all_texts = []

        for page_index in range(len(pdf)):
            page = pdf[page_index]
            # Rendu à 200 DPI pour une bonne qualité OCR
            bitmap = page.render(scale=200 / 72)
            pil_image = bitmap.to_pil()
            page_text = _run_ocr_on_pil(pil_image)
            if page_text:
                all_texts.append(f"[Page {page_index + 1}]\n{page_text}")

        pdf.close()
        return "\n\n".join(all_texts).strip()

    except ImportError:
        logger.error("pypdfium2 n'est pas installé. Installez-le avec : pip install pypdfium2")
        return ""
    except Exception as e:
        logger.error(f"Erreur lors de l'extraction PDF : {e}")
        return ""


# ─────────────────────────────────────────────
# Fonctions publiques
# ─────────────────────────────────────────────

def extract_text_from_file(file_obj) -> str:
    """
    Extrait le texte d'un fichier uploadé.
    Détecte automatiquement si c'est un PDF ou une image.
    Accepte : chemin str, InMemoryUploadedFile Django, ou BytesIO.
    """
    if not ocr_model:
        logger.error("EasyOCR n'est pas initialisé.")
        return ""
    try:
        # Si c'est un chemin string, on ouvre le fichier en binaire
        if isinstance(file_obj, str):
            with open(file_obj, 'rb') as f:
                content = f.read()
            file_like = io.BytesIO(content)
            if content[:4] == b'%PDF':
                return _extract_text_from_pdf(file_like)
            else:
                image = Image.open(file_like)
                return _run_ocr_on_pil(image)
        else:
            # C'est un file object (InMemoryUploadedFile ou BytesIO)
            if _is_pdf(file_obj):
                return _extract_text_from_pdf(file_obj)
            else:
                image = Image.open(file_obj)
                return _run_ocr_on_pil(image)
    except Exception as e:
        logger.error(f"Erreur lors de l'extraction du fichier : {e}")
        return ""


# Alias rétrocompatible (ancienne signature)
def extract_text_from_image(image_file) -> str:
    return extract_text_from_file(image_file)


def extract_text_from_base64(base64_string: str) -> str:
    """
    Extrait le texte d'une image encodée en base64.
    Utilisé pour les captures caméra (WebRTC) depuis le frontend.
    Accepte le format data URI : data:image/jpeg;base64,/9j/...
    """
    try:
        if ',' in base64_string:
            base64_string = base64_string.split(',', 1)[1]
        image_data = base64.b64decode(base64_string)
        image_file = io.BytesIO(image_data)
        return extract_text_from_file(image_file)
    except Exception as e:
        logger.error(f"Erreur décodage base64 : {e}")
        return ""


# ─────────────────────────────────────────────
# Extraction structurée des données CNI
# ─────────────────────────────────────────────

def _parse_cni_fields(text: str) -> dict:
    """
    Parse les champs structurés d'une CNI sénégalaise CEDEAO
    à partir du texte brut extrait par OCR.
    """
    data = {
        "nom": "",
        "prenom": "",
        "numero_cni": "",
        "date_naissance": "",
        "lieu_naissance": "",
        "date_expiration": ""
    }

    # --- NOM ---
    match = re.search(r'(?:^|\n)(?:NOM|Nom)\s*[:\n\r]+\s*([A-ZÀÂÄÉÈÊËÎÏÔÙÛÜÇ][A-ZÀÂÄÉÈÊËÎÏÔÙÛÜÇ\s\-]+)', text, re.IGNORECASE | re.MULTILINE)
    if not match:
        match = re.search(r'(?:NOM|Nom)[\s:]+([A-Z][A-Z\s\-]+)', text, re.IGNORECASE)
    if match:
        data["nom"] = match.group(1).strip().split('\n')[0]

    # --- PRENOM ---
    match = re.search(r'(?:PRENOM|Prenom|Prénom|Prénoms)[\s:\n\r]+([A-ZÀÂÄÉÈÊËÎÏÔÙÛÜÇ][A-Za-zÀ-ÿ\s\-]+)', text, re.IGNORECASE)
    if match:
        data["prenom"] = match.group(1).strip().split('\n')[0]

    # --- NUMERO CNI (format sénégalais) ---
    match = re.search(r'\b(\d[\s]?\d{2}[\s]?\d{8}[\s]?\d{5})\b', text)
    if match:
        data["numero_cni"] = match.group(1).strip()

    # --- DATES ---
    dates = re.findall(r'\b(\d{2}/\d{2}/\d{4})\b', text)

    match_dob = re.search(r'(?:Date de naissance|Né\(e\) le)[\s:\n\r]+(\d{2}/\d{2}/\d{4})', text, re.IGNORECASE)
    if match_dob:
        data["date_naissance"] = match_dob.group(1).strip()
    elif dates:
        data["date_naissance"] = dates[0]

    match_exp = re.search(r"(?:Expire le|Date.{0,10}expiration|dexpiration|d'expiration)[\s:\n\r]+(\d{2}/\d{2}/\d{4})", text, re.IGNORECASE)
    if match_exp:
        data["date_expiration"] = match_exp.group(1).strip()
    elif len(dates) >= 2:
        data["date_expiration"] = dates[-1]

    # --- LIEU DE NAISSANCE ---
    match = re.search(r'(?:Lieu de naissance|Lleu de naissance)[\s:\n\r]+([A-ZÀÂÄÉÈÊËÎÏÔÙÛÜÇ][A-Za-zÀ-ÿ\s\-]+)', text, re.IGNORECASE)
    if match:
        data["lieu_naissance"] = match.group(1).strip().split('\n')[0]

    return data


def _parse_extrait_naissance_fields(text: str) -> dict:
    """
    Parse les champs structurés d'un extrait d'acte de naissance
    (registre civil sénégalais) à partir du texte brut extrait par OCR.

    Champs extraits :
      - numero_registre   : numéro de l'acte dans le registre
      - annee_registre    : année du registre
      - commune           : nom de la commune de déclaration
      - date_naissance    : date de naissance de la personne concernée
      - nom               : nom de famille
      - prenom            : prénoms
    """
    data = {
        "numero_registre": "",
        "annee_registre": "",
        "commune": "",
        "date_naissance": "",
        "nom": "",
        "prenom": "",
    }

    # --- NUMÉRO D'ACTE / REGISTRE ---
    match = re.search(
        r'(?:N[°o]?\s*(?:acte|registre|de l[\'’]acte)?)[\s:\-]*(\d+)',
        text, re.IGNORECASE
    )
    if match:
        data["numero_registre"] = match.group(1).strip()
    else:
        # Format court ex: "Acte n° 42" ou "N° 042"
        match = re.search(r'\bN[°o]\.?\s*(\d{1,5})\b', text, re.IGNORECASE)
        if match:
            data["numero_registre"] = match.group(1).strip()

    # --- ANNÉE DU REGISTRE ---
    match = re.search(
        r'(?:année|an)[\s:\-]*(\d{4})\b',
        text, re.IGNORECASE
    )
    if match:
        data["annee_registre"] = match.group(1).strip()
    else:
        # Chercher une année 4 chiffres dans un contexte registre
        match = re.search(r'registre[^\d]*(\d{4})', text, re.IGNORECASE)
        if match:
            data["annee_registre"] = match.group(1).strip()

    # --- COMMUNE ---
    match = re.search(
        r'(?:commune|mairie|centre d[\'\u2019]état civil)[\s:de]+([ \w\-\u00e0-\u00ff]+)',
        text, re.IGNORECASE
    )
    if match:
        data["commune"] = match.group(1).strip().split('\n')[0]

    # --- DATE DE NAISSANCE ---
    match = re.search(
        r'(?:né\(e\) le|date de naissance|née? le)[\s:\-]+(\d{2}[/\-\s]\d{2}[/\-\s]\d{4})',
        text, re.IGNORECASE
    )
    if match:
        data["date_naissance"] = match.group(1).strip().replace('-', '/').replace(' ', '/')
    else:
        # Fallback : première date trouvée sous format JJ/MM/AAAA
        dates = re.findall(r'\b(\d{2}/\d{2}/\d{4})\b', text)
        if dates:
            data["date_naissance"] = dates[0]

    # --- NOM ---
    match = re.search(
        r'(?:^|\n)(?:NOM|Nom)[\s:\n\r]+([A-Z\u00c0-\u00dc][A-Z\u00c0-\u00dc\s\-]+)',
        text, re.IGNORECASE | re.MULTILINE
    )
    if match:
        data["nom"] = match.group(1).strip().split('\n')[0]

    # --- PRÉNOM ---
    match = re.search(
        r'(?:PRÉNOM|Prenom|Prénom|Prénoms)[\s:\n\r]+([A-Z\u00c0-\u00dc][A-Za-z\u00c0-\u00ff\s\-]+)',
        text, re.IGNORECASE
    )
    if match:
        data["prenom"] = match.group(1).strip().split('\n')[0]

    return data


def extract_cni_data(file_obj, dossier_type: str = 'cni') -> dict:
    """
    Extrait les données structurées d'un document depuis un fichier image ou PDF.

    Args:
        file_obj   : fichier uploadé (InMemoryUploadedFile, BytesIO, ou chemin str)
        dossier_type : type de document à parser :
                       - 'birth_certificate' → parseur extrait de naissance
                       - tout autre (ou 'cni') → parseur CNI (défaut)
    """
    text = extract_text_from_file(file_obj)
    if dossier_type == 'birth_certificate':
        return _parse_extrait_naissance_fields(text)
    return _parse_cni_fields(text)


def extract_cni_data_from_base64(base64_string: str, dossier_type: str = 'cni') -> dict:
    """Extrait les données structurées depuis une image base64 (caméra)."""
    text = extract_text_from_base64(base64_string)
    if dossier_type == 'birth_certificate':
        return _parse_extrait_naissance_fields(text)
    return _parse_cni_fields(text)
