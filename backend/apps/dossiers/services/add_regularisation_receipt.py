import os
from django.conf import settings
from apps.documents.models import GeneratedCertificate
from apps.documents.crypto import compute_pdf_hash, build_payload, sign_payload
from apps.dossiers.services.pdf_generator import (
    _draw_watermark, _draw_official_header, _draw_cartouche_section,
    _draw_seal, get_seal_assets
)
from reportlab.lib.units import cm
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
import qrcode
from io import BytesIO
from django.core.files.base import ContentFile
import datetime

def _draw_regularisation_receipt_content(p, width, height, dossier, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    # Pas de filigrane ni bandeau couleur, texte brut
    p.setFont("Helvetica-Bold", 12)
    y = height - 2*cm
    
    p.drawString(2*cm, y, "RÉPUBLIQUE DU SÉNÉGAL")
    p.setFont("Helvetica", 10)
    y -= 15
    p.drawString(2*cm, y, "Un Peuple - Un But - Une Foi")
    y -= 25
    
    region = dossier.commune.region if dossier.commune and hasattr(dossier.commune, 'region') else "N/A"
    departement = dossier.commune.department if dossier.commune and hasattr(dossier.commune, 'department') else "N/A"
    commune = dossier.commune.name if dossier.commune and hasattr(dossier.commune, 'name') else "N/A"

    p.drawString(2*cm, y, f"RÉGION DE : {region.upper()}")
    y -= 15
    p.drawString(2*cm, y, f"DÉPARTEMENT DE : {departement.upper()}")
    y -= 15
    p.drawString(2*cm, y, f"COMMUNE DE : {commune.upper()}")
    y -= 30

    p.line(2*cm, y, width - 2*cm, y)
    y -= 20

    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(width/2.0, y, "RÉCÉPISSÉ DE DÉPÔT DE DOSSIER")
    y -= 30

    now = dossier.submitted_at or datetime.datetime.now()
    date_str = now.strftime('%d / %m / %Y')
    time_str = now.strftime('%H h %M')
    
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Numéro de dossier : ")
    p.setFont("Helvetica", 11)
    p.drawString(6*cm, y, f"{dossier.reference}")
    y -= 15

    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Date de dépôt : ")
    p.setFont("Helvetica", 11)
    p.drawString(6*cm, y, f"{date_str}")
    y -= 15
    
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Heure de dépôt : ")
    p.setFont("Helvetica", 11)
    p.drawString(6*cm, y, f"{time_str}")
    y -= 15

    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Statut : ")
    p.setFont("Helvetica", 11)
    p.drawString(6*cm, y, "DOSSIER REÇU")
    y -= 30

    metadata = dossier.metadata or {}
    citizen = dossier.citizen
    nom_complet = metadata.get('nom_complet_requerant') or (citizen.full_name if citizen else "") or "Non renseigné"
    cni = metadata.get('numero_cni') or (citizen.profile.cni_number if citizen and hasattr(citizen, 'profile') else "") or "Non renseigné"
    tel = metadata.get('telephone') or (citizen.phone if citizen else "") or "Non renseigné"
    adresse = metadata.get('adresse') or (citizen.profile.address if citizen and hasattr(citizen, 'profile') else "") or "Non renseignée"

    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Informations du requérant")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Nom et prénom : ")
    p.setFont("Helvetica", 10)
    p.drawString(6*cm, y, f"{nom_complet}")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Numéro CNI : ")
    p.setFont("Helvetica", 10)
    p.drawString(6*cm, y, f"{cni}")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Téléphone : ")
    p.setFont("Helvetica", 10)
    p.drawString(6*cm, y, f"{tel}")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Adresse : ")
    p.setFont("Helvetica", 10)
    p.drawString(6*cm, y, f"{adresse}")
    y -= 30

    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Objet de la demande")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Type de demande : ")
    p.setFont("Helvetica", 10)
    p.drawString(6*cm, y, "Régularisation de terrain communal")
    y -= 30

    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Informations sur le terrain")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Localisation du terrain : ")
    p.setFont("Helvetica", 10)
    p.drawString(7*cm, y, f"{metadata.get('localisation_terrain') or 'Non renseignée'}")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Quartier / Village : ")
    p.setFont("Helvetica", 10)
    p.drawString(7*cm, y, f"{metadata.get('quartier_village') or 'Non renseigné'}")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Superficie (si connue) : ")
    p.setFont("Helvetica", 10)
    p.drawString(7*cm, y, f"{metadata.get('superficie') or 'Non renseignée'}")
    y -= 15
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Référence cadastrale : ")
    p.setFont("Helvetica", 10)
    p.drawString(7*cm, y, f"{metadata.get('reference_cadastrale') or 'Non applicable'}")
    y -= 30
    
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Pièces fournies")
    y -= 15
    p.setFont("Helvetica", 10)
    p.drawString(2*cm, y, "☑ Demande de régularisation adressée au Maire")
    y -= 15
    p.drawString(2*cm, y, "☑ Photocopie de la pièce d'identité du requérant")
    y -= 15
    p.drawString(2*cm, y, "☑ Acte original du terrain")
    y -= 15
    p.drawString(2*cm, y, "☐ Autres pièces : Aucune")
    y -= 30
    
    p.setFont("Helvetica-Bold", 11)
    p.drawString(2*cm, y, "Suivi du dossier")
    y -= 15
    p.setFont("Helvetica", 10)
    p.drawString(2*cm, y, "Votre dossier a été enregistré et sera examiné par les services compétents de la commune.")
    y -= 15
    p.drawString(2*cm, y, "Vous pouvez suivre son évolution à l'aide du numéro de dossier indiqué ci-dessus.")
    y -= 25

    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Étapes possibles :")
    y -= 15
    p.setFont("Helvetica", 10)
    p.drawString(2*cm, y, "- Dossier reçu")
    y -= 15
    p.drawString(2*cm, y, "- En cours d'instruction")
    y -= 15
    p.drawString(2*cm, y, "- En attente de complément")
    y -= 15
    p.drawString(2*cm, y, "- Validé")
    y -= 15
    p.drawString(2*cm, y, "- Rejeté")
    y -= 15
    p.drawString(2*cm, y, "- Clôturé")
    
    y = 6*cm
    p.setFont("Helvetica", 10)
    p.drawString(width - 8*cm, y, f"Fait à : {commune}")
    y -= 15
    p.drawString(width - 8*cm, y, f"Le : {now.strftime('%d/%m/%Y')}")
    y -= 20

    agent_name = dossier.assigned_agent.full_name if dossier.assigned_agent else "Non assigné"
    p.setFont("Helvetica-Bold", 10)
    p.drawString(width - 8*cm, y, "Agent réceptionnaire")
    y -= 15
    p.setFont("Helvetica", 10)
    p.drawString(width - 8*cm, y, f"Nom et prénom : {agent_name}")
    y -= 15
    p.drawString(width - 8*cm, y, "Fonction : Agent Guichet")
    y -= 20

    p.setFont("Helvetica-Bold", 10)
    p.drawString(width - 8*cm, y, "Signature et cachet")
    y -= 10
    
    _draw_seal(p, cachet_path, width - 8*cm, y - 3*cm, 3*cm, commune, "communal")
    
    if qr_image_reader:
        p.drawImage(qr_image_reader, 2*cm, y - 3*cm, width=3*cm, height=3*cm)


def generate_regularisation_receipt(dossier):
    cachet_communal_path = ''
    signature_officier_path = ''
    cachet_nominal_path = ''

    if dossier.commune:
        if dossier.commune.chemin_cachet_communal:
            cachet_communal_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_cachet_communal)
        if dossier.commune.chemin_signature_officier:
            signature_officier_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_signature_officier)
        if dossier.commune.chemin_cachet_nominal:
            cachet_nominal_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_cachet_nominal)
        
        if not cachet_communal_path or not signature_officier_path or not cachet_nominal_path:
            c_path, s_path, n_path = get_seal_assets(dossier.commune.name)
            cachet_communal_path = cachet_communal_path or c_path
            signature_officier_path = signature_officier_path or s_path
            cachet_nominal_path = cachet_nominal_path or n_path
                    
    if not cachet_communal_path:
        cachet_communal_path = 'DYNAMIC'
    if not signature_officier_path:
        signature_officier_path = 'DYNAMIC'
    if not cachet_nominal_path:
        cachet_nominal_path = 'DYNAMIC'

    # Raw PDF
    buffer_raw = BytesIO()
    p_raw = canvas.Canvas(buffer_raw, pagesize=A4)
    _draw_regularisation_receipt_content(
        p_raw, A4[0], A4[1], dossier, cachet_communal_path, signature_officier_path, cachet_nominal_path, None
    )
    p_raw.save()
    raw_pdf_bytes = buffer_raw.getvalue()

    pdf_hash = compute_pdf_hash(raw_pdf_bytes)

    # Payload
    nom_citoyen = dossier.citizen.full_name if dossier.citizen else "Inconnu"
    date_ref = dossier.submitted_at.strftime('%Y-%m-%d') if dossier.submitted_at else "Inconnue"
    
    payload_str = build_payload(
        dossier_reference=dossier.reference,
        commune_name=dossier.commune.name if dossier.commune else 'N/A',
        citizen_name=nom_citoyen,
        date_naissance='N/A',
        officier_id='System',
        pdf_sha256=pdf_hash
    )
    signature = sign_payload(payload_str)

    frontend_url = getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')
    verification_url = f"{frontend_url}/verify?ref={dossier.reference}&sig={signature}"
    qr = qrcode.QRCode(version=1, box_size=10, border=2)
    qr.add_data(verification_url)
    qr.make(fit=True)
    img_qr = qr.make_image(fill_color="black", back_color="white")
    
    qr_buffer = BytesIO()
    img_qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    from reportlab.lib.utils import ImageReader
    qr_image_reader = ImageReader(qr_buffer)

    # Final PDF
    buffer_final = BytesIO()
    p_final = canvas.Canvas(buffer_final, pagesize=A4)
    _draw_regularisation_receipt_content(
        p_final, A4[0], A4[1], dossier, cachet_communal_path, signature_officier_path, cachet_nominal_path, qr_image_reader
    )
    p_final.save()
    final_pdf_bytes = buffer_final.getvalue()

    cert, _ = GeneratedCertificate.objects.get_or_create(dossier=dossier)
    cert.officier = None
    cert.data_payload = payload_str
    cert.pdf_sha256 = pdf_hash
    cert.hmac_signature = signature
    cert.cachet_communal_svg = cachet_communal_path
    cert.signature_officier_svg = signature_officier_path
    
    pdf_filename = f"Recepisse_{dossier.reference}.pdf"
    cert.pdf_file.save(pdf_filename, ContentFile(final_pdf_bytes), save=False)
    cert.save()

    return cert
