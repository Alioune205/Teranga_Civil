from io import BytesIO
from rest_framework.exceptions import ValidationError
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor

from apps.dossiers.services.pdf_generator import (
    number_to_french_words,
    get_registration_datetime_in_words,
    _draw_signatures_and_seals,
    clean_val
)
from apps.dossiers.services.pdf_generators.dates_lettres import date_to_french_words

def generer_copie_litterale_naissance(dossier, officier, cachet_path='', signature_path='', cachet_nominal_path=''):
    """
    Génère le PDF de la copie littérale d'acte de naissance selon le format officiel sénégalais.
    """
    if dossier.status != 'completed':
        raise ValidationError("Le dossier doit être finalisé avant de générer la copie littérale")
    
    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    NOIR = HexColor('#000000')
    metadata = dossier.metadata or {}
    
    # --- RECUPERATION DONNEES ---
    nin = "NIN non renseigné"
    if hasattr(dossier.citizen, 'profile') and dossier.citizen.profile.cni_number:
        nin = dossier.citizen.profile.cni_number
    elif hasattr(dossier, 'citoyen_guichet') and dossier.citoyen_guichet and dossier.citoyen_guichet.numero_cni:
        nin = dossier.citoyen_guichet.numero_cni

    commune = dossier.commune
    region = clean_val(getattr(commune, 'region', '')).upper()
    commune_name = clean_val(getattr(commune, 'name', '')).upper()
    
    numero_registre = str(metadata.get('numero_registre') or metadata.get('registre', 'N/A'))
    annee_registre = str(metadata.get('annee_registre', 'N/A'))
    
    annee_words, mois_part, time_words = get_registration_datetime_in_words(dossier, metadata)
    
    from datetime import datetime
    dt_dressage = getattr(dossier, 'completed_at', None) or datetime.now()
    try:
        jour_d_words = number_to_french_words(dt_dressage.day)
    except:
        jour_d_words = str(dt_dressage.day)
        
    citizen = dossier.citizen
    prenoms_enfant = clean_val(metadata.get('prenoms_enfant') or (citizen.first_name if citizen else "")).upper()
    nom_enfant = clean_val(metadata.get('nom_enfant') or (citizen.last_name if citizen else "")).upper()
    nom_complet_enfant = f"{prenoms_enfant} {nom_enfant}".strip()
    
    date_naissance_raw = clean_val(metadata.get('date_naissance_personne') or metadata.get('date_naissance') or (str(citizen.profile.date_of_birth) if citizen and hasattr(citizen, 'profile') else ""), default="N/A")
    date_naissance_words = date_to_french_words(date_naissance_raw)
    heure_naissance = clean_val(metadata.get('heure_naissance'), default="zéro")
    lieu_naissance = clean_val(metadata.get('lieu_naissance') or metadata.get('lieu_naissance_enfant') or (citizen.profile.place_of_birth if citizen and hasattr(citizen, 'profile') else ""), default="N/A")
    sexe = clean_val(metadata.get('sexe') or (citizen.profile.get_gender_display() if citizen and hasattr(citizen, 'profile') else ""), default="N/A")
    
    if sexe.lower() in ['m', 'masculin']:
        sexe_complet = 'Masculin'
        ne_str = "est né"
    elif sexe.lower() in ['f', 'féminin']:
        sexe_complet = 'Féminin'
        ne_str = "est née"
    else:
        sexe_complet = 'Non précisé'
        ne_str = "est né(e)"
        
    prenom_pere = clean_val(metadata.get('prenom_pere'), default="")
    nom_pere = clean_val(metadata.get('nom_pere'), default="")
    nom_complet_pere = f"{prenom_pere} {nom_pere}".strip() or "N/A"
    profession_pere = clean_val(metadata.get('profession_pere'), default="N/A")
    adresse_pere = clean_val(metadata.get('adresse_pere'), default="N/A")
    
    prenom_mere = clean_val(metadata.get('prenom_mere'), default="")
    nom_mere = clean_val(metadata.get('nom_mere'), default="")
    nom_complet_mere = f"{prenom_mere} {nom_mere}".strip() or "N/A"
    
    statut_brut = clean_val(metadata.get('statut_matrimonial_mere'), default="")
    if statut_brut.lower() == "son épouse" or not statut_brut:
        statut_matrimonial_mere = "son épouse"
    else:
        statut_matrimonial_mere = f"{statut_brut}, son épouse"
        
    adresse_mere = clean_val(metadata.get('adresse_mere'), default="N/A")
    nom_declarant = clean_val(metadata.get('nom_declarant'), default="N/A")
    officier_name = officier.full_name if officier else clean_val(metadata.get('officier_nom'), default="L'Officier d'État Civil")

    # --- DESSIN PDF ---
    p.setFillColor(NOIR)
    
    # 1. EN-TÊTE
    y_header = height - 1.5 * cm
    p.setFont("Helvetica", 9)
    # Gauche
    p.drawString(2.0 * cm, y_header, f"REGION DE {region}")
    p.drawString(2.0 * cm, y_header - 0.45 * cm, f"Ville de {commune_name}")
    p.drawString(2.0 * cm, y_header - 1.35 * cm, "-")
    p.drawString(2.0 * cm, y_header - 1.80 * cm, f"CENTRE PRINCIPAL DE {commune_name}")
    
    # Droite
    x_droite = width * 0.75
    p.setFont("Times-Roman", 12)
    p.drawCentredString(x_droite, y_header, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica", 9)
    p.drawCentredString(x_droite, y_header - 0.45 * cm, "UN PEUPLE - UN BUT - UNE FOI")
    p.drawCentredString(x_droite, y_header - 0.90 * cm, "-------------")
    
    # 2. TITRE
    y_titre = y_header - 2.5 * cm
    p.setFont("Times-Roman", 13)
    p.drawCentredString(width / 2, y_titre, "COPIE LITTERALE")
    p.setFont("Times-Bold", 17)
    p.drawCentredString(width / 2, y_titre - 0.7 * cm, "D'ACTE DE NAISSANCE")
    p.setFont("Times-Roman", 9)
    p.drawCentredString(width / 2, y_titre - 1.2 * cm, "DELIVREE AUX PERSONNES DESIGNNEES PAR LE CODE")
    p.drawCentredString(width / 2, y_titre - 1.6 * cm, "DE LA FAMILLE (II.LOI 61-33 DU 21 JUIN 1961)")
    
    # 3. ZONE PRINCIPALE
    y_debut_zone = y_titre - 3.0 * cm
    lh = 0.55 * cm
    
    # Colonne Gauche
    p.setFont("Helvetica", 10)
    p.drawString(2.0 * cm, y_debut_zone, f"N°  {numero_registre}/{annee_registre}")
    
    try:
        annee_courte = str(dt_dressage.year)
    except:
        annee_courte = annee_registre
    p.drawString(2.0 * cm, y_debut_zone - lh, f"Le  {jour_d_words} {mois_part} {annee_courte}")
    
    p.drawString(2.0 * cm, y_debut_zone - lh * 3.5, "Naissance de")
    p.drawString(2.0 * cm, y_debut_zone - lh * 4.5, nom_complet_enfant)
    
    # Colonne Droite
    hauteur_bloc_gauche = lh * 4.5 + 0.3 * cm
    y = y_debut_zone - hauteur_bloc_gauche - 0.5 * cm
    
    p.drawString(7.0 * cm, y, "Le")
    p.drawString(7.8 * cm, y, date_naissance_words)
    y -= lh
    
    if ':' in heure_naissance:
        parts = heure_naissance.split(':')
        h = parts[0]
        m = parts[1]
        h_words = number_to_french_words(int(h)) if h.isdigit() else h
        m_words = number_to_french_words(int(m)) if m.isdigit() else m
        heure_str = f"{h_words} heure(s)  {m_words} minute(s)"
    else:
        heure_str = heure_naissance + " heure(s)  zéro minute(s)"
        
    p.drawString(7.0 * cm, y, "à")
    p.drawString(7.8 * cm, y, heure_str)
    p.drawRightString(width - 2.0 * cm, y, ne_str + " à")
    y -= lh
    
    p.drawString(7.0 * cm, y, lieu_naissance)
    y -= lh
    p.drawString(7.0 * cm, y, commune_name)
    y -= lh
    p.drawString(7.0 * cm, y, nom_complet_enfant)
    y -= lh * 1.5
    
    p.drawString(7.0 * cm, y, "De sexe")
    p.drawString(8.5 * cm, y, sexe_complet)
    y -= lh * 1.5
    
    p.drawString(7.0 * cm, y, "De")
    p.drawString(7.6 * cm, y, nom_complet_pere)
    y -= lh
    p.drawString(7.0 * cm, y, profession_pere)
    y -= lh
    
    if adresse_pere and adresse_pere != "N/A":
        p.drawString(7.0 * cm, y, f"Domicile {adresse_pere}")
    else:
        p.drawString(7.0 * cm, y, "Domicile")
    y -= lh
    
    p.drawString(7.0 * cm, y, "Et de")
    p.drawString(8.0 * cm, y, nom_complet_mere)
    y -= lh
    p.drawString(7.0 * cm, y, statut_matrimonial_mere)
    y -= lh
    
    if adresse_mere and adresse_mere != "N/A":
        p.drawString(7.0 * cm, y, f"Domicile {adresse_mere}")
    else:
        p.drawString(7.0 * cm, y, "Domicile")
    y -= lh
    
    p.drawString(7.0 * cm, y, "Dressé le")
    p.drawString(8.6 * cm, y, f"{jour_d_words} {mois_part} {annee_words}")
    y -= lh
    p.drawString(7.0 * cm, y, "Sur la déclaration de")
    p.drawString(10.6 * cm, y, f". NIN : {nin} .-")
    y -= lh * 1.5
    
    p.drawString(7.0 * cm, y, "QUI LECTURE FAITE, A SIGNE AVEC NOUS")
    y -= lh
    p.drawString(7.3 * cm, y, officier_name)
    y -= lh * 2.0
    
    p.drawString(7.0 * cm, y, f"OFFICIER DE L'ETAT-CIVIL  CENTRE PRINCIPAL DE {commune_name}")
    
    # 4. BAS DE PAGE
    y_mentions = y - 1.5 * cm
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2.0 * cm, y_mentions, "MENTIONS MARGINALES")
    
    y_conforme = y_mentions - 1.5 * cm
    p.drawString(2.0 * cm, y_conforme, "POUR COPIE CONFORME")
    
    y_fait = y_conforme - 1.5 * cm
    p.setFont("Helvetica", 10)
    
    # Textes d'authentification (à droite)
    x_droite_sign = width * 0.70
    p.drawCentredString(x_droite_sign, y_fait, f"FAIT à {commune_name} le {jour_d_words} {mois_part} {annee_words}")
    
    y_sign = y_fait - 0.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(x_droite_sign, y_sign, "L'OFFICIER DE L'ETAT-CIVIL")
    
    import os
    import qrcode
    from reportlab.lib.utils import ImageReader
    from apps.dossiers.services.pdf_generator import _draw_seal
    
    # --- QR Code à gauche ---
    qr = qrcode.QRCode(version=1, box_size=10, border=1)
    dossier_id = getattr(dossier, 'id', '12345')
    qr.add_data(f"https://teranga-civil.sn/verify/copie-litterale/{dossier_id}")
    qr.make(fit=True)
    img_qr = qr.make_image(fill_color="black", back_color="white")
    qr_buffer = BytesIO()
    img_qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    qr_image_reader = ImageReader(qr_buffer)
    
    qr_size = 2.5 * cm
    qr_x = 2.0 * cm
    qr_y = y_sign - 3.0 * cm
    p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
    p.setFont("Helvetica", 6)
    p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.3 * cm, "Vérifier l'authenticité")

    # --- Cachets et Signature (à droite) ---
    seal_y = y_sign - 4.0 * cm
    
    # 1. Cachet Communal (Gauche du bloc)
    _draw_seal(p, cachet_path, x_droite_sign - 3.0 * cm, seal_y, 3.2 * cm, commune_name=commune_name, seal_type="communal")
    
    # 2. Cachet Nominal (Droite du bloc)
    _draw_seal(p, cachet_nominal_path, x_droite_sign + 0.5 * cm, seal_y, 3.2 * cm, commune_name=commune_name, seal_type="nominal", officier_name=officier_name)
    
    # 3. Signature (Entre les deux cachets, par-dessus)
    if signature_path and signature_path != 'DYNAMIC' and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), x_droite_sign - 1.5 * cm, seal_y + 0.5 * cm, width=3.5 * cm, height=2.0 * cm, mask='auto')
    
    p.showPage()
    p.save()
    buffer.seek(0)
    return buffer
