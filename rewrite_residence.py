import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

# I will replace the entire _draw_residence_pdf_content function
old_func_pattern = r'def _draw_residence_pdf_content\(p, width, height, dossier, officier, timbre_ref,.*?(?=\ndef _draw_mariage_pdf_content)'

new_func = """def _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref,
                                cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    \"\"\"Dessine le certificat de résidence au format A4 Paysage.\"\"\"
    from reportlab.platypus import Paragraph
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.enums import TA_CENTER
    from reportlab.lib.colors import HexColor

    VERT = HexColor('#00853F')
    NOIR = HexColor('#000000')
    BLEU_FONCE = HexColor('#0F172A')
    ROUGE = HexColor('#E31B23')

    metadata = dossier.metadata or {}
    citizen = dossier.citizen

    # En-tête gauche
    y = height - 2 * cm
    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(5 * cm, y, "Un Peuple - Un But - Une Foi")
    y -= 0.6 * cm
    p.setFont("Helvetica-Bold", 14)
    p.setFillColor(BLEU_FONCE)
    region = dossier.commune.region if dossier.commune and dossier.commune.region else "DAKAR"
    p.drawCentredString(5 * cm, y, f"REGION DE {region.upper()}")
    y -= 0.5 * cm
    p.setFont("Helvetica-Bold", 11)
    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"
    p.drawCentredString(5 * cm, y, f"COMMUNE DE {commune_name.upper()}")

    # Titre droit
    p.setFont("Helvetica-Bold", 26)
    p.setFillColor(BLEU_FONCE)
    p.drawString(14 * cm, height - 3 * cm, "CERTIFICAT DE RESIDENCE")
    p.setStrokeColor(NOIR)
    p.setLineWidth(1)
    p.line(18.5 * cm, height - 3.4 * cm, 23.5 * cm, height - 3.4 * cm)

    # Référence
    y_ref = height - 5 * cm
    p.setFont("Helvetica", 14)
    p.setFillColor(NOIR)
    p.drawString(15 * cm, y_ref, f"N° Pièce portée : {dossier.reference}")

    # Données
    prenoms = metadata.get('prenoms_requerant') or (citizen.first_name if citizen else "")
    nom = metadata.get('nom_requerant') or (citizen.last_name if citizen else "")
    nom_complet = f"{prenoms} {nom}".strip()
    date_naissance = metadata.get('date_naissance') or (str(citizen.profile.date_of_birth) if citizen and hasattr(citizen, 'profile') else "")
    lieu_naissance = metadata.get('lieu_naissance') or (citizen.profile.place_of_birth if citizen and hasattr(citizen, 'profile') else "")
    adresse = metadata.get('adresse') or (citizen.profile.address if citizen and hasattr(citizen, 'profile') else "")
    quartier = metadata.get('quartier', '')
    date_installation = metadata.get('date_installation', '')

    # --- CORPS DU TEXTE ---
    TEXT_X = 3 * cm
    TEXT_Y = height - 8.5 * cm  # On démarre plus haut pour laisser place en bas
    TEXT_W = width - 6 * cm

    style_center = ParagraphStyle(
        name='Center', fontName='Helvetica', fontSize=19, leading=28, alignment=TA_CENTER
    )
    
    texte_complet = (
        f"Nous soussigné(e) Maire de la Commune de {commune_name.capitalize()} certifions "
        f"que {nom_complet} né(e) le {date_naissance} à {lieu_naissance} et qu'il (elle) "
        f"réside à {adresse} au quartier {quartier} depuis {date_installation}."
    )
    
    para = Paragraph(texte_complet, style_center)
    para.wrap(TEXT_W, 10 * cm) # max height
    
    # On dessine le paragraphe, il "descend" depuis TEXT_Y
    para.drawOn(p, TEXT_X, TEXT_Y - para.height)
    
    # Position Y libre après le texte (avec marge de 1.0 cm)
    y_body = TEXT_Y - para.height - 1.0 * cm

    # ======= LIGNE B : VALIDATION (DROITE) =======
    # On ancre la ligne B en dessous du texte (y_body)
    # Mais on s'assure qu'elle ne descend pas trop bas (min 6.0 cm depuis le bas pour que les cachets rentrent)
    l_b_y = min(y_body, 6.0 * cm) 
    
    images_width = 12.0 * cm 
    start_images_x = width - 2.0 * cm - images_width 
    
    from datetime import datetime
    date_str = dossier.updated_at.strftime("%d/%m/%Y") if dossier.updated_at else datetime.now().strftime("%d/%m/%Y")
    
    text_y = l_b_y - 0.5 * cm
    p.setFont("Helvetica", 10)
    p.drawCentredString(start_images_x + images_width/2, text_y, f"Fait à {commune_name.capitalize()}, le {date_str}")
    p.setFont("Helvetica-Bold", 10)
    p.drawCentredString(start_images_x + images_width/2, text_y - 0.4 * cm, officier.full_name if officier else "L'Officier de l'État Civil")
    p.setFont("Helvetica", 10)
    p.drawCentredString(start_images_x + images_width/2, text_y - 0.8 * cm, "Officier de l'État Civil")

    # Images des cachets, placés SOUS le texte
    l_b_images_y = text_y - 1.2 * cm - 4.0 * cm
    
    c1_x = start_images_x
    if cachet_path and os.path.exists(cachet_path):
        p.drawImage(ImageReader(cachet_path), c1_x, l_b_images_y, width=4.0*cm, height=4.0*cm, mask='auto')
        
    sig_w = 3.4 * cm
    sig_h = 1.5 * cm
    sig_x = c1_x + 4.0 * cm + 0.3 * cm
    if signature_path and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), sig_x, l_b_images_y + 1.25*cm, width=sig_w, height=sig_h, mask='auto')
        
    c2_x = sig_x + sig_w + 0.3 * cm
    if cachet_nominal_path and os.path.exists(cachet_nominal_path):
        p.drawImage(ImageReader(cachet_nominal_path), c2_x, l_b_images_y, width=4.0*cm, height=4.0*cm, mask='auto')


    # ======= LIGNE A : VÉRIFICATION (GAUCHE) =======
    # Placée tout en bas de la page, à gauche
    l_a_x = 2.0 * cm
    qr_size = 2.5 * cm
    qr_y = 1.5 * cm  
    
    if qr_image_reader:
        p.drawImage(qr_image_reader, l_a_x, qr_y, width=qr_size, height=qr_size)
    else:
        import hashlib
        import qrcode
        from io import BytesIO
        
        hash_content = f"{dossier.reference}".encode('utf-8')
        doc_hash = hashlib.sha256(hash_content).hexdigest()
        qr_data = f"https://teranga-civil.sn/verify/{doc_hash}"
        
        qr = qrcode.QRCode(version=1, box_size=10, border=1)
        qr.add_data(qr_data)
        qr.make(fit=True)
        img_qr = qr.make_image(fill_color="black", back_color="white")
        qr_buffer = BytesIO()
        img_qr.save(qr_buffer, format="PNG")
        qr_buffer.seek(0)
        p.drawImage(ImageReader(qr_buffer), l_a_x, qr_y, width=qr_size, height=qr_size)

    p.setFont("Helvetica", 6)
    p.drawCentredString(l_a_x + qr_size/2, qr_y - 0.2 * cm, "Scannez pour vérifier")
    p.drawCentredString(l_a_x + qr_size/2, qr_y - 0.5 * cm, "l'authenticité")
    p.drawCentredString(l_a_x + qr_size/2, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    # Timbre juste à côté du QR
    timbre_x = l_a_x + qr_size + 0.5 * cm
    if timbre_ref:
        _draw_secure_timbre(p, timbre_x, qr_y, timbre_ref)
        
    # Mention de validité au-dessus de la Ligne A (sur sa propre ligne, sans chevauchement)
    # Le QR Code fait 2.5 cm de haut, il s'arrête à Y = 4.0 cm. On place la mention à Y = 4.5 cm.
    p.setFont("Helvetica-Bold", 10)
    p.setFillColor(ROUGE)
    p.drawString(l_a_x, qr_y + qr_size + 0.5 * cm, "Validité : 3 mois à compter de la date de délivrance")
    p.setFillColor(NOIR)
"""

if re.search(old_func_pattern, text, flags=re.DOTALL):
    text = re.sub(old_func_pattern, new_func, text, flags=re.DOTALL)
    with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
        f.write(text)
    print("Residence fully rewritten!")
else:
    print("Could not find the function to replace!")

