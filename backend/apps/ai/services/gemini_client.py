import os
import json
import logging
import io
from PIL import Image
from decouple import config
from google import genai
from google.genai import types

logger = logging.getLogger(__name__)

# Configure Gemini
api_key = config("GEMINI_API_KEY", default=None)
client = None
if api_key:
    try:
        client = genai.Client(api_key=api_key)
    except Exception as e:
        logger.error(f"Erreur init Gemini : {e}")
else:
    logger.warning("GEMINI_API_KEY non trouvée dans le fichier .env")

def analyze_document_with_gemini(image_obj) -> dict:
    """
    Envoie l'image à Gemini 2.5 Flash pour effectuer l'OCR et l'extraction structurée en une seule passe.
    Retourne le JSON complet.
    """
    if not client:
        logger.error("API Key Gemini manquante.")
        return {}

    try:
        # Si l'image est un chemin de fichier ou un objet fichier (PDF ou Image)
        if isinstance(image_obj, str) and os.path.exists(image_obj):
            with open(image_obj, 'rb') as f:
                content = f.read()
        elif isinstance(image_obj, bytes):
            content = image_obj
        elif hasattr(image_obj, 'read'):
            content = image_obj.read()
            image_obj.seek(0)
        else:
            # On suppose que c'est déjà un objet PIL
            img = image_obj
            content = None

        if content:
            # Vérifier si c'est un PDF (signature %PDF)
            if content.startswith(b'%PDF'):
                try:
                    import pypdfium2 as pdfium
                    pdf = pdfium.PdfDocument(content)
                    page = pdf[0] # On prend la première page
                    bitmap = page.render(scale=200 / 72)
                    img = bitmap.to_pil()
                    pdf.close()
                except ImportError:
                    logger.error("pypdfium2 non installé pour traiter le PDF.")
                    return {}
            else:
                img = Image.open(io.BytesIO(content))

        # Conversion en RGB pour éviter les soucis de canal Alpha (PNG)
        if hasattr(img, 'convert'):
            img = img.convert('RGB')

        system_prompt = """
        Tu es un expert en documents administratifs de l'état civil sénégalais.
        Analyse l'image fournie de manière très détaillée.
        
        Retourne UNIQUEMENT un objet JSON avec cette structure exacte :
        {
           "document_type": "acte_naissance" (choisis parmi: acte_naissance, acte_mariage, acte_deces, certificat_residence, certificat_celibat, certificat_vie, certificat_prise_en_charge, certificat_heredite, certificat_bonne_vie_moeurs, cni, jugement_suppletif, autorisation_construire, mutation_parcelle, pv_verification, inconnu),
           "confidence": 0.95,
           "raw_text": "Le texte brut complet lu sur le document.",
           "structured_data": {
               // Si acte_naissance: "nom", "prenom", "sexe", "date_naissance", "heure_naissance", "lieu_naissance", "pere", "mere", "numero_registre", "annee_registre", "centre_etat_civil"
               // Si acte_mariage: "epoux", "epouse", "date_mariage", "lieu_mariage", "numero_registre", "annee_registre"
               // Si acte_deces: "nom_defunt", "prenom_defunt", "date_deces", "heure_deces", "lieu_deces", "numero_registre", "annee_registre"
               // Si cni: "numero_cni", "nom", "prenom", "date_naissance", "lieu_naissance", "sexe", "nationalite", "date_delivrance", "date_expiration"
               // Si certificat_residence: "nom", "prenom", "adresse", "date_delivrance"
               // Laisse la valeur vide ("") si le champ est introuvable.
           },
           "metadata": {
               "numero_registre": "",
               "annee_registre": "",
               "date_delivrance": "",
               "centre_etat_civil": "",
               "commune": "",
               "departement": "",
               "region": ""
           }
        }
        """

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[system_prompt, img],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.1,
            ),
        )
        
        return json.loads(response.text)
        
    except Exception as e:
        logger.error(f"Erreur Gemini Vision : {e}")
        return {}
