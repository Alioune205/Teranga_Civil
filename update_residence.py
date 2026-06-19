import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

# The old 7, 8, 9 zones and the Validité
old_footer_pattern = r'    # --- 7\. BLOC SIGNATURE ---.*?(?=\ndef _draw_mariage_pdf_content)'

new_footer = """    # ======= NOUVELLE RÉORGANISATION EN 2 LIGNES SUPERPOSÉES =======
    # LIGNE B (Validation) au-dessus, LIGNE A (Vérification) en dessous.
    zone_y = 1.5 * cm 
    
    # === LIGNE A (En bas, alignée à gauche) ===
    # On laisse la mention de validité juste sous le cadre
    p.setFont("Helvetica-Bold", 10)
    p.setFillColor(ROUGE)
    p.drawString(CADRE_X, CADRE_Y - 0.8 * cm, "Validité : 3 mois à compter de la date de délivrance")
    p.setFillColor(NOIR)
    
    l_a_x = 2.0 * cm
    qr_size = 2.5 * cm
    qr_y = zone_y + 0.8 * cm  
    
    if qr_image_reader:
        p.drawImage(qr_image_reader, l_a_x, qr_y, width=qr_size, height=qr_size)
    else:
        # Placeholder fonctionnel pour le test sans API complète
        import hashlib
        import qrcode
        from io import BytesIO
        from reportlab.lib.utils import ImageReader
        
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

    timbre_x = l_a_x + qr_size + 0.5 * cm
    if timbre_ref:
        _draw_secure_timbre(p, timbre_x, qr_y, timbre_ref)
        
    # === LIGNE B (Au-dessus de Ligne A, alignée à droite) ===
    l_b_images_y = qr_y + qr_size + 0.5 * cm
    images_width = 12.0 * cm 
    start_images_x = width - 2.0 * cm - images_width 
    
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

    text_y = l_b_images_y + 4.0 * cm + 0.3 * cm 
    
    from datetime import datetime
    date_str = dossier.updated_at.strftime("%d/%m/%Y") if dossier.updated_at else datetime.now().strftime("%d/%m/%Y")
    
    p.setFont("Helvetica", 10)
    p.drawCentredString(start_images_x + images_width/2, text_y + 0.8 * cm, f"Fait à {commune_name.capitalize()}, le {date_str}")
    p.setFont("Helvetica-Bold", 10)
    p.drawCentredString(start_images_x + images_width/2, text_y + 0.4 * cm, officier.full_name if officier else "L'Officier de l'État Civil")
    p.setFont("Helvetica", 10)
    p.drawCentredString(start_images_x + images_width/2, text_y, "Officier de l'État Civil")
"""

if re.search(old_footer_pattern, text, flags=re.DOTALL):
    text = re.sub(old_footer_pattern, new_footer, text, flags=re.DOTALL)
    with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
        f.write(text)
    print("Residence footer updated!")
else:
    print("Failed to match pattern")
