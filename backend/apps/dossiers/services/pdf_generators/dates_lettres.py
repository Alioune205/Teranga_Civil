import re
from apps.dossiers.services.pdf_generator import number_to_french_words

def date_to_french_words(date_str):
    """
    Convertit une date "JJ/MM/AAAA" ou "YYYY-MM-DD" en toutes lettres.
    Ex: "12/04/1990" -> "douze avril mille neuf cent quatre-vingt-dix"
    """
    if not date_str or date_str == "N/A":
        return date_str

    # Tentative d'extraction de chiffres
    parts = []
    if "/" in date_str:
        parts = date_str.split("/")
    elif "-" in date_str:
        parts = date_str.split("-")
        parts.reverse() # YYYY-MM-DD -> DD, MM, YYYY
        
    if len(parts) == 3:
        try:
            jour = int(parts[0])
            mois = int(parts[1])
            annee = int(parts[2])
            
            french_months = {
                1: "janvier", 2: "février", 3: "mars", 4: "avril", 5: "mai", 6: "juin",
                7: "juillet", 8: "août", 9: "septembre", 10: "octobre", 11: "novembre", 12: "décembre"
            }
            
            jour_str = "premier" if jour == 1 else number_to_french_words(jour)
            mois_str = french_months.get(mois, str(mois))
            annee_str = number_to_french_words(annee)
            
            return f"{jour_str} {mois_str} {annee_str}"
        except ValueError:
            pass
            
    return date_str
