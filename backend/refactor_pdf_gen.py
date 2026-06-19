import os
import re
import textwrap

file_path = r'C:\Users\senep\Desktop\Teranga-Civil-Developpe\backend\apps\dossiers\services\pdf_generator.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_code = textwrap.dedent('''
# --- NEW DESIGN CONSTANTS ---
COLOR_VERT = HexColor('#00853F')
COLOR_JAUNE = HexColor('#FDEF42')
COLOR_ROUGE = HexColor('#E31B23')
COLOR_NOIR = HexColor('#000000')
COLOR_BG_CARTOUCHE = HexColor('#F9FAFB')
COLOR_BORDER = HexColor('#E5E7EB')
COLOR_GRIS = HexColor('#6B7280')

def _draw_watermark(p, width, height):
    p.saveState()
    p.setFillAlpha(0.04)
    p.setStrokeAlpha(0.04)
    p.translate(width/2, height/2)
    p.rotate(45)
    p.setFont("Helvetica-Bold", 70)
    p.setFillColor(HexColor('#888888'))
    for x in range(-int(20*cm), int(20*cm), int(15*cm)):
        for y in range(-int(20*cm), int(20*cm), int(10*cm)):
            p.drawCentredString(x, y, "BAOBAB - ÉTAT CIVIL")
    p.restoreState()

def _draw_official_header(p, width, height, commune, title, reference):
    banner_h = 0.3 * cm
    p.setFillColor(COLOR_VERT)
    p.rect(0, height - banner_h, width/3, banner_h, stroke=0, fill=1)
    p.setFillColor(COLOR_JAUNE)
    p.rect(width/3, height - banner_h, width/3, banner_h, stroke=0, fill=1)
    p.setFillColor(COLOR_ROUGE)
    p.rect(2*width/3, height - banner_h, width/3, banner_h, stroke=0, fill=1)

    y = height - 2.0 * cm
    p.setFillColor(COLOR_NOIR)
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(width / 2, y, "RÉPUBLIQUE DU SÉNÉGAL")
    
    y -= 0.5 * cm
    p.setFont("Helvetica-Oblique", 10)
    p.drawCentredString(width / 2, y, "Un Peuple — Un But — Une Foi")

    y -= 0.8 * cm
    p.setFont("Helvetica-Bold", 10)
    region = commune.region if commune and hasattr(commune, 'region') and commune.region else "N/A"
    p.drawCentredString(width / 2, y, f"RÉGION DE {region.upper()}")

    y -= 0.5 * cm
    p.setFont("Helvetica-Bold", 11)
    p.setFillColor(COLOR_VERT)
    commune_name = commune.name if commune else "N/A"
    p.drawCentredString(width / 2, y, f"CENTRE D'ÉTAT CIVIL DE {commune_name.upper()}")

    p.setStrokeColor(COLOR_BORDER)
    p.setLineWidth(1)
    y -= 0.3 * cm
    p.line(4 * cm, y, width - 4 * cm, y)

    y -= 1.0 * cm
    p.setFillColor(COLOR_NOIR)
    p.setFont("Helvetica-Bold", 16)
    p.drawCentredString(width / 2, y, title.upper())
    
    y -= 0.6 * cm
    p.setFont("Helvetica", 10)
    p.drawCentredString(width / 2, y, f"Réf. Document : {reference}")

    return y - 1.0 * cm

def _draw_cartouche_section(p, width, start_y, title, lines_data):
    row_h = 0.7 * cm
    content_h = len(lines_data) * row_h
    total_h = content_h + 1.2 * cm
    
    box_x = 2.0 * cm
    box_w = width - 4.0 * cm
    box_y = start_y - total_h

    p.setFillColor(COLOR_BG_CARTOUCHE)
    p.setStrokeColor(COLOR_BORDER)
    p.setLineWidth(1)
    p.roundRect(box_x, box_y, box_w, total_h, 4, stroke=1, fill=1)

    p.setFillColor(COLOR_VERT)
    p.roundRect(box_x, box_y, 0.3*cm, total_h, 4, stroke=0, fill=1)
    p.rect(box_x + 0.15*cm, box_y, 0.15*cm, total_h, stroke=0, fill=1)

    p.setFillColor(COLOR_VERT)
    p.setFont("Helvetica-Bold", 11)
    p.drawString(box_x + 0.8 * cm, start_y - 0.7 * cm, title.upper())

    current_y = start_y - 1.4 * cm
    for i, row in enumerate(lines_data):
        if i % 2 == 1:
            p.setFillColor(HexColor('#F3F4F6'))
            p.rect(box_x + 0.3*cm, current_y - 0.2*cm, box_w - 0.3*cm, row_h, stroke=0, fill=1)

        p.setFillColor(COLOR_GRIS)
        p.setFont("Helvetica", 9)
        if len(row) >= 2:
            p.drawString(box_x + 1.0 * cm, current_y, f"{row[0]} : ")
            p.setFillColor(COLOR_NOIR)
            p.setFont("Helvetica-Bold", 9)
            p.drawString(box_x + 4.0 * cm, current_y, str(row[1]))
        
        if len(row) == 4 and row[2]:
            p.setFillColor(COLOR_GRIS)
            p.setFont("Helvetica", 9)
            p.drawString(box_x + 10.0 * cm, current_y, f"{row[2]} : ")
            p.setFillColor(COLOR_NOIR)
            p.setFont("Helvetica-Bold", 9)
            p.drawString(box_x + 13.0 * cm, current_y, str(row[3]))

        current_y -= row_h
        
    return box_y - 0.5 * cm

def _draw_official_footer(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    footer_y = 6.0 * cm
    p.setStrokeColor(COLOR_BORDER)
    p.setLineWidth(1)
    p.line(2 * cm, footer_y, width - 2 * cm, footer_y)
    
    qr_x = 2.0 * cm
    qr_size = 2.5 * cm
    qr_y = footer_y - 3.5 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
        p.setFillColor(COLOR_NOIR)
        p.setFont("Helvetica", 7)
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.3 * cm, "Vérifier l'authenticité")

    if timbre_ref:
        _draw_secure_timbre(p, qr_x + qr_size + 1.0 * cm, qr_y, timbre_ref)

    sig_zone_x = width - 11.0 * cm
    p.setFillColor(COLOR_NOIR)
    p.setFont("Helvetica", 9)
    commune_name = dossier.commune.name.capitalize() if dossier.commune else "N/A"
    from datetime import datetime
    date_str = dossier.updated_at.strftime('%d/%m/%Y') if dossier.updated_at else datetime.now().strftime('%d/%m/%Y')
    p.drawCentredString(sig_zone_x + 4.5 * cm, footer_y - 0.6 * cm, f"Fait à {commune_name}, le {date_str}")
    p.setFont("Helvetica-Bold", 9)
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"
    p.drawCentredString(sig_zone_x + 4.5 * cm, footer_y - 1.1 * cm, officier_name)

    seal_size = 3.2 * cm
    seal_y = footer_y - 4.5 * cm
    _draw_seal(p, cachet_path, sig_zone_x, seal_y, seal_size)
    if signature_path and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), sig_zone_x + 3.0*cm, seal_y + 0.5*cm, width=3.0*cm, height=1.5*cm, mask='auto')
    if cachet_nominal_path:
        _draw_seal(p, cachet_nominal_path, sig_zone_x + 5.8*cm, seal_y, seal_size)

    p.setFillColor(COLOR_GRIS)
    p.setFont("Helvetica-Oblique", 7)
    p.drawCentredString(width / 2, 0.8 * cm, "Document généré électroniquement - SUNU CIVIL / Teranga Civil. Ce document est sécurisé par une empreinte cryptographique (HMAC-SHA256).")

def _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    _draw_watermark(p, width, height)
    y = _draw_official_header(p, width, height, dossier.commune, "CERTIFICAT DE RÉSIDENCE", dossier.reference)
    
    metadata = dossier.metadata or {}
    citizen = dossier.citizen
    prenoms = metadata.get('prenoms_requerant') or (citizen.first_name if citizen else "")
    nom = metadata.get('nom_requerant') or (citizen.last_name if citizen else "")
    nom_complet = f"{prenoms} {nom}".strip()
    date_naissance = metadata.get('date_naissance') or (str(citizen.profile.date_of_birth) if citizen and hasattr(citizen, 'profile') else "")
    lieu_naissance = metadata.get('lieu_naissance') or (citizen.profile.place_of_birth if citizen and hasattr(citizen, 'profile') else "")
    adresse = metadata.get('adresse') or (citizen.profile.address if citizen and hasattr(citizen, 'profile') else "")
    quartier = metadata.get('quartier', '')
    date_installation = metadata.get('date_installation', '')

    y = _draw_cartouche_section(p, width, y, "Informations du Résident", [
        ("Nom Complet", nom_complet, "Né(e) le", date_naissance),
        ("Lieu de Naissance", lieu_naissance, "", ""),
    ])
    
    y = _draw_cartouche_section(p, width, y, "Détails de la Résidence", [
        ("Adresse Principale", adresse, "Quartier", quartier),
        ("Date d'installation", date_installation, "", ""),
    ])

    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"
    quartier_text = f" au quartier {quartier}" if quartier and quartier.strip() else ""
    texte_complet = (f"Nous soussigné(e) Maire de la Commune de {commune_name.capitalize()} certifions "
                     f"que {nom_complet} né(e) le {date_naissance} à {lieu_naissance} et qu'il (elle) "
                     f"réside à {adresse}{quartier_text} depuis {date_installation}.")

    p.setFillColor(COLOR_NOIR)
    p.setFont("Helvetica-Oblique", 11)
    para = Paragraph(texte_complet, ParagraphStyle(name='Center', fontName='Helvetica-Oblique', fontSize=12, leading=18, alignment=TA_CENTER))
    para.wrap(width - 6 * cm, 5 * cm)
    para.drawOn(p, 3 * cm, y - para.height - 0.5 * cm)

    _draw_official_footer(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

def _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    _draw_watermark(p, width, height)
    y = _draw_official_header(p, width, height, dossier.commune, "EXTRAIT DU REGISTRE DES ACTES DE MARIAGE", dossier.reference)

    metadata = dossier.metadata or {}
    
    y = _draw_cartouche_section(p, width, y, "Époux", [
        ("Nom", metadata.get('nom_epoux', ''), "Prénoms", metadata.get('prenom_epoux', '')),
        ("Date Naiss.", metadata.get('date_naissance_epoux', ''), "Lieu", metadata.get('lieu_naissance_epoux', '')),
        ("Profession", metadata.get('profession_epoux', ''), "Domicile", metadata.get('domicile_epoux', '')),
        ("Fils de", f"{metadata.get('prenom_pere_epoux', '')} {metadata.get('nom_pere_epoux', '')}", "Et de", f"{metadata.get('prenom_mere_epoux', '')} {metadata.get('nom_mere_epoux', '')}"),
    ])

    y = _draw_cartouche_section(p, width, y, "Épouse", [
        ("Nom", metadata.get('nom_epouse', ''), "Prénoms", metadata.get('prenom_epouse', '')),
        ("Date Naiss.", metadata.get('date_naissance_epouse', ''), "Lieu", metadata.get('lieu_naissance_epouse', '')),
        ("Profession", metadata.get('profession_epouse', ''), "Domicile", metadata.get('domicile_epouse', '')),
        ("Fille de", f"{metadata.get('prenom_pere_epouse', '')} {metadata.get('nom_pere_epouse', '')}", "Et de", f"{metadata.get('prenom_mere_epouse', '')} {metadata.get('nom_mere_epouse', '')}"),
    ])

    y = _draw_cartouche_section(p, width, y, "Détails du Mariage", [
        ("Célébré le", metadata.get('date_marriage', ''), "Option", metadata.get('option_souscrite', 'Monogamie')),
        ("Régime", metadata.get('regime_matrimonial', 'séparation des biens'), "Registre N°", str(metadata.get('registre_marriage') or metadata.get('registre', 'N/A'))),
    ])

    _draw_official_footer(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

def _draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    _draw_watermark(p, width, height)
    y = _draw_official_header(p, width, height, dossier.commune, "CERTIFICAT DE DÉCÈS", dossier.reference)

    metadata = dossier.metadata or {}
    
    y = _draw_cartouche_section(p, width, y, "Informations du Défunt(e)", [
        ("Nom", metadata.get('nom_defunt', ''), "Prénoms", metadata.get('prenom_defunt', '')),
        ("Sexe", metadata.get('sexe_defunt', ''), "Nationalité", metadata.get('nationalite_defunt', '')),
        ("Né(e) le", metadata.get('date_naissance_defunt', ''), "À", metadata.get('lieu_naissance_defunt', '')),
        ("Profession", metadata.get('profession_defunt', ''), "Domicile", metadata.get('adresse_defunt', '')),
    ])

    y = _draw_cartouche_section(p, width, y, "Détails du Décès", [
        ("Date du décès", metadata.get('date_deces', ''), "Heure", metadata.get('heure_deces', '')),
        ("Lieu du décès", metadata.get('lieu_deces', ''), "", ""),
    ])

    y = _draw_cartouche_section(p, width, y, "Déclarant", [
        ("Nom & Prénom", metadata.get('nom_declarant', ''), "Lien", metadata.get('lien_declarant', '')),
        ("Pièce d'Identité", metadata.get('cni_declarant', ''), "", ""),
    ])

    _draw_official_footer(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

def _draw_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    _draw_watermark(p, width, height)
    
    type_display = dossier.get_type_display().upper() if hasattr(dossier, 'get_type_display') else "EXTRAIT DE NAISSANCE"
    title = "EXTRAIT DU REGISTRE DES ACTES DE NAISSANCE" if dossier.type == 'birth_certificate' else type_display
    
    y = _draw_official_header(p, width, height, dossier.commune, title, dossier.reference)
    
    metadata = dossier.metadata or {}
    citizen = dossier.citizen

    prenoms_enfant = metadata.get('prenoms_enfant')
    nom_enfant = metadata.get('nom_enfant')
    date_naissance_personne = metadata.get('date_naissance_personne')
    lieu_naissance = metadata.get('lieu_naissance')
    sexe = metadata.get('sexe')

    if not dossier.metadata.get('is_for_third_party') and citizen:
        prenoms_enfant = prenoms_enfant or citizen.first_name
        nom_enfant = nom_enfant or citizen.last_name
        if hasattr(citizen, 'profile'):
            date_naissance_personne = date_naissance_personne or str(citizen.profile.date_of_birth)
            lieu_naissance = lieu_naissance or citizen.profile.place_of_birth
            sexe = sexe or citizen.profile.get_gender_display()
        
    nom_enfant = nom_enfant or metadata.get('nom') or 'N/A'
    prenoms_enfant = prenoms_enfant or 'N/A'
    date_naissance_personne = date_naissance_personne or metadata.get('date_naissance') or 'N/A'
    lieu_naissance = lieu_naissance or 'N/A'
    sexe = sexe or 'N/A'

    annee_registre = str(metadata.get('annee_registre', 'N/A'))
    numero_registre = str(metadata.get('numero_registre') or metadata.get('registre', 'N/A'))
    
    dept_name = dossier.commune.department if dossier.commune and hasattr(dossier.commune, 'department') and dossier.commune.department else "N/A"
    commune_name = dossier.commune.name if dossier.commune else "N/A"

    y = _draw_cartouche_section(p, width, y, "Informations Administratives", [
        ("Département", dept_name, "Commune", commune_name),
        ("Année Registre", annee_registre, "Numéro Registre", numero_registre),
    ])

    y = _draw_cartouche_section(p, width, y, "Informations de l'Enfant", [
        ("Prénoms", prenoms_enfant, "Nom", nom_enfant),
        ("Né(e) le", date_naissance_personne, "Heure", metadata.get('heure_naissance', 'Non précisée')),
        ("Lieu", lieu_naissance, "Sexe", sexe),
    ])

    y = _draw_cartouche_section(p, width, y, "Informations des Parents", [
        ("Prénom Père", metadata.get('prenom_pere', 'N/A'), "", ""),
        ("Prénoms Mère", metadata.get('prenom_mere', 'N/A'), "Nom Mère", metadata.get('nom_mere', 'N/A')),
    ])

    if metadata.get('est_jugement_suppletif'):
        y = _draw_cartouche_section(p, width, y, "Jugement d'Autorisation d'Inscription", [
            ("Tribunal", metadata.get('tribunal_competent', 'N/A'), "N° Jugement", metadata.get('numero_jugement', 'N/A')),
            ("Date Jugement", metadata.get('date_jugement', 'N/A'), "Date Inscription", f"{metadata.get('date_inscription', 'N/A')} ({metadata.get('annee_inscription', '')})"),
        ])

    _draw_official_footer(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
''')

start_match = re.search(r'def _draw_residence_pdf_content\(', content)
end_match = re.search(r'def generate_signed_certificate\(', content)

if start_match and end_match:
    start_idx = start_match.start()
    end_idx = end_match.start()
    updated_content = content[:start_idx] + "\n" + new_code + "\n\n" + content[end_idx:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(updated_content)
    print("Refactoring successful!")
else:
    print("Regex bounds not found.")
