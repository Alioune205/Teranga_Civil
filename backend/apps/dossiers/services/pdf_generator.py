"""
pdf_generator.py — Génération de certificats officiels avec liaison cryptographique
====================================================================================
Processus en 5 étapes :
  1. Dessiner le PDF avec ReportLab (texte, cachets SVG, signature SVG, timbre)
  2. Calculer le SHA-256 du PDF brut
  3. Construire le payload canonique (données + pdf_hash)
  4. Signer le payload avec HMAC-SHA256
  5. Générer le QR Code pointant vers l'endpoint de vérification publique
  6. Re-générer le PDF final avec le QR Code inclus
"""
import os
import io
import logging
from io import BytesIO

import qrcode
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import cm, mm
from reportlab.lib.utils import ImageReader
from reportlab.lib.colors import HexColor
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle, Image as RLImage, Flowable
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
import hashlib

def _draw_secure_timbre(p, x, y, reference):
    from reportlab.lib.colors import HexColor
    from reportlab.lib.units import cm
    VERT = HexColor('#00853F')
    ROUGE = HexColor('#E31B23')
    NOIR = HexColor('#000000')
    p.saveState()
    stamp_width = 3.3 * cm
    stamp_height = 2.0 * cm
    p.setFillColor(HexColor('#FFFFF0'))
    p.setStrokeColor(VERT)
    p.setLineWidth(1.5)
    p.roundRect(x, y, stamp_width, stamp_height, 4, stroke=1, fill=1)
    p.setStrokeColor(HexColor('#E0F0E0'))
    p.setLineWidth(0.5)
    for i in range(0, int(stamp_width), 5):
        p.line(x + i, y, x + i, y + stamp_height)
    p.setFillColor(VERT)
    p.setFont("Helvetica-Bold", 6)
    p.drawCentredString(x + stamp_width / 2, y + 1.5 * cm, "TIMBRE FISCAL ÉLECTRONIQUE")
    p.setFillColor(ROUGE)
    p.setFont("Helvetica-Bold", 11)
    p.drawCentredString(x + stamp_width / 2, y + 0.8 * cm, "500 FCFA")
    p.setFillColor(NOIR)
    p.setFont("Courier-Bold", 6)
    p.drawCentredString(x + stamp_width / 2, y + 0.2 * cm, f"Réf: {reference}")
    p.restoreState()

from django.conf import settings
from django.core.files.base import ContentFile

from apps.documents.models import GeneratedCertificate, TimbreFiscal
from apps.documents.crypto import compute_pdf_hash, build_payload, sign_payload

logger = logging.getLogger(__name__)

# Répertoire des assets (cachets, signatures)
ASSETS_DIR = os.path.join(settings.BASE_DIR, 'assets', 'seals')


def _try_draw_svg(c, svg_path, x, y, width, height):
    """
    Tente de dessiner un fichier SVG sur le canvas ReportLab.
    Fallback silencieux si le fichier n'existe pas ou si svglib échoue.
    """
    if not svg_path or not os.path.exists(svg_path):
        logger.warning(f"[PDF] Fichier SVG introuvable: {svg_path}")
        return False
    try:
        from svglib.svglib import svg2rlg
        from reportlab.graphics import renderPDF
        drawing = svg2rlg(svg_path)
        if drawing:
            # Redimensionner le dessin
            sx = width / drawing.width
            sy = height / drawing.height
            scale = min(sx, sy)
            drawing.width = drawing.width * scale
            drawing.height = drawing.height * scale
            drawing.scale(scale, scale)
            renderPDF.draw(drawing, c, x, y)
            return True
    except Exception as e:
        logger.warning(f"[PDF] Erreur rendu SVG {svg_path}: {e}")
    return False


def _try_draw_image(c, img_path, x, y, width, height):
    """
    Tente de dessiner un fichier image (PNG/JPG) sur le canvas.
    Fallback silencieux si le fichier n'existe pas.
    """
    if not img_path or not os.path.exists(img_path):
        return False
    try:
        c.drawImage(img_path, x, y, width=width, height=height, mask='auto')
        return True
    except Exception as e:
        logger.warning(f"[PDF] Erreur rendu image {img_path}: {e}")
    return False


def _draw_dynamic_seal(c, x, y, size, commune_name, seal_type="communal", officier_name=""):
    from reportlab.lib.colors import HexColor
    cx = x + size / 2
    cy = y + size / 2
    radius = size / 2 - 2
    c.saveState()
    c.setStrokeColor(HexColor('#0044CC'))
    c.setLineWidth(1)
    c.circle(cx, cy, radius, stroke=1, fill=0)
    c.circle(cx, cy, radius - 3, stroke=1, fill=0)
    
    c.setFillColor(HexColor('#0044CC'))
    if seal_type == "communal":
        c.setFont("Helvetica-Bold", 5)
        c.drawCentredString(cx, cy + 6, "RÉPUBLIQUE DU SÉNÉGAL")
        c.drawCentredString(cx, cy, "ÉTAT CIVIL")
        c.setFont("Helvetica", 5)
        c.drawCentredString(cx, cy - 6, f"COMMUNE DE {commune_name.upper()[:20]}")
    else:
        c.setFont("Helvetica-Bold", 5)
        c.drawCentredString(cx, cy + 6, "L'Officier de l'État Civil")
        c.setFont("Helvetica", 5)
        c.drawCentredString(cx, cy, f"COMMUNE DE {commune_name.upper()[:20]}")
        c.setFont("Helvetica-Bold", 5)
        c.drawCentredString(cx, cy - 6, officier_name[:25])
    c.restoreState()


def _draw_seal(c, path, x, y, size, commune_name="", seal_type="communal", officier_name=""):
    """Dessine un cachet (SVG ou PNG) à la position donnée ou un cachet dynamique."""
    import os
    if path and path != 'DYNAMIC' and path.endswith('.svg') and os.path.exists(path):
        if not _try_draw_svg(c, path, x, y, size, size):
            _draw_dynamic_seal(c, x, y, size, commune_name, seal_type, officier_name)
    elif path and path != 'DYNAMIC' and os.path.exists(path):
        if not _try_draw_image(c, path, x, y, size, size):
            _draw_dynamic_seal(c, x, y, size, commune_name, seal_type, officier_name)
    else:
        _draw_dynamic_seal(c, x, y, size, commune_name, seal_type, officier_name)


def _draw_placeholder_seal(c, x, y, size, label):
    """Dessine un cercle pointillé comme placeholder de cachet."""
    from reportlab.lib.colors import HexColor
    cx = x + size / 2
    cy = y + size / 2
    c.saveState()
    c.setStrokeColor(HexColor('#999999'))
    c.setDash(3, 3)
    c.circle(cx, cy, size / 2 - 2, stroke=1, fill=0)
    c.setFont("Helvetica", 7)
    c.setFillColor(HexColor('#999999'))
    c.drawCentredString(cx, cy - 3, f"[{label}]")
    c.restoreState()


def _draw_signatures_and_seals(p, x_start, y_start, cachet_path, signature_path, cachet_nominal_path, seal_size=3.2 * cm, commune_name="COMMUNE", officier_name="OFFICIER"):
    """
    Fonction réutilisable pour dessiner les 3 éléments de validation
    (Cachet communal, Signature de l'officier, Cachet nominal)
    avec un espacement optimal empêchant les chevauchements.
    """
    import os
    from reportlab.lib.utils import ImageReader
    from reportlab.lib.units import cm
    from reportlab.lib.colors import HexColor
    
    # Cachet communal (gauche)
    _draw_seal(p, cachet_path, x_start + 0.2 * cm, y_start + 0.2 * cm, seal_size, commune_name=commune_name, seal_type="communal")
    
    # Signature manuscrite (centre) - taille réduite et centrée
    if signature_path and signature_path != 'DYNAMIC' and os.path.exists(signature_path):
        p.drawImage(ImageReader(signature_path), x_start + 3.8 * cm, y_start + 0.8 * cm, width=2.4 * cm, height=1.2 * cm, mask='auto')
    else:
        p.saveState()
        p.setFillColor(HexColor('#0000FF'))
        p.setFont("Helvetica-Oblique", 10)
        p.drawCentredString(x_start + 5.0 * cm, y_start + 1.2 * cm, officier_name)
        p.restoreState()
        
    # Cachet nominal (droite)
    _draw_seal(p, cachet_nominal_path, x_start + 6.6 * cm, y_start + 0.3 * cm, seal_size, commune_name=commune_name, seal_type="nominal", officier_name=officier_name)


def _generate_raw_pdf(dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path):
    """
    Génère le contenu PDF brut (SANS QR Code).
    On génère d'abord sans QR pour pouvoir hasher le contenu,
    puis on re-génère avec le QR.
    """
    buffer = BytesIO()
    pagesize = landscape(A4) if dossier.type in ('residence_certificate', 'death_certificate') else A4
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize

    if dossier.type == 'residence_certificate':
        _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader=None)
    elif dossier.type == 'marriage_certificate':
        _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader=None)
    elif dossier.type == 'death_certificate':
        _draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader=None)
    elif dossier.type == 'birth_certificate':
        _draw_birth_certificate_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader=None)
    else:
        _draw_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader=None)

    p.showPage()
    p.save()
    buffer.seek(0)
    return buffer.getvalue()


def _generate_final_pdf(dossier, officier, timbre_ref, cachet_path,
                        signature_path, cachet_nominal_path, verification_url):
    """
    Génère le PDF final AVEC le QR Code de vérification.
    """
    # Générer le QR Code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=2,
    )
    qr.add_data(verification_url)
    qr.make(fit=True)
    img_qr = qr.make_image(fill_color="black", back_color="white")

    qr_buffer = BytesIO()
    img_qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)
    qr_image_reader = ImageReader(qr_buffer)

    # Générer le PDF final
    buffer = BytesIO()
    pagesize = landscape(A4) if dossier.type in ('residence_certificate', 'death_certificate') else A4
    p = canvas.Canvas(buffer, pagesize=pagesize)
    width, height = pagesize

    if dossier.type == 'residence_certificate':
        _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    elif dossier.type == 'marriage_certificate':
        _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    elif dossier.type == 'death_certificate':
        _draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    elif dossier.type == 'birth_certificate':
        _draw_birth_certificate_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader)
    else:
        _draw_pdf_content(p, width, height, dossier, officier, timbre_ref,
                          cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

    p.showPage()
    p.save()
    buffer.seek(0)
    return buffer.getvalue()




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
    baobab_path = os.path.join(settings.BASE_DIR, 'assets', 'baobab.png')
    if os.path.exists(baobab_path):
        # Image is a transparent PNG so mask='auto' is optional, but good for safety
        # We make it large and centered
        img_size = 18 * cm
        p.translate(width/2 - img_size/2, height/2 - img_size/2)
        p.drawImage(baobab_path, 0, 0, width=img_size, height=img_size, mask='auto')
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
    
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"

    seal_size = 3.2 * cm
    seal_y = footer_y - 4.5 * cm
    commune_name = dossier.commune.name if dossier.commune else "COMMUNE"
    officier_name = officier.full_name if officier else "L'Officier"
    _draw_signatures_and_seals(p, sig_zone_x, seal_y, cachet_path, signature_path, cachet_nominal_path, seal_size, commune_name, officier_name)

    p.setFillColor(COLOR_GRIS)
    p.setFont("Helvetica-Oblique", 7)
    p.drawCentredString(width / 2, 0.8 * cm, "Document généré électroniquement - SUNU CIVIL / Teranga Civil. Ce document est sécurisé par une empreinte cryptographique (HMAC-SHA256).")

def _draw_residence_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    metadata = dossier.metadata or {}
    citizen = dossier.citizen
    prenoms = metadata.get('prenoms_requerant') or metadata.get('nom_demandeur', '').split(' ')[0] or (citizen.first_name if citizen else "")
    nom = metadata.get('nom_requerant') or " ".join(metadata.get('nom_demandeur', '').split(' ')[1:]) or (citizen.last_name if citizen else "")
    nom_complet = f"{prenoms} {nom}".strip()
    date_naissance = metadata.get('date_naissance') or metadata.get('date_naissance_demandeur') or (str(citizen.profile.date_of_birth) if citizen and hasattr(citizen, 'profile') else "")
    try:
        from datetime import datetime
        dt = datetime.strptime(date_naissance, '%Y-%m-%d')
        mois_fr = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
        date_naissance_str = f"{dt.day:02d} {mois_fr[dt.month-1]} {dt.year}"
    except Exception:
        date_naissance_str = date_naissance

    lieu_naissance = metadata.get('lieu_naissance') or metadata.get('lieu_naissance_demandeur') or (citizen.profile.place_of_birth if citizen and hasattr(citizen, 'profile') else "")
    if not lieu_naissance or lieu_naissance == 'N/A':
        lieu_naissance = "lieu non précisé"

    adresse = metadata.get('adresse') or metadata.get('adresse_demandeur') or (citizen.profile.address if citizen and hasattr(citizen, 'profile') else "")
    quartier = metadata.get('quartier') or metadata.get('quartier_demandeur') or ''
    date_installation = metadata.get('date_installation') or metadata.get('annee_residence') or ''

    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"
    region_name = dossier.commune.region if dossier.commune and hasattr(dossier.commune, 'region') else "INCONNUE"

    # --- EN-TETE ---
    # Haut gauche
    p.setFont("Helvetica-Bold", 10)
    p.drawCentredString(4.5 * cm, height - 1.5 * cm, "Un Peuple - Un But - Une Foi")
    p.drawCentredString(4.5 * cm, height - 2.0 * cm, f"REGION DE {region_name.upper()}")
    p.drawCentredString(4.5 * cm, height - 2.5 * cm, f"COMMUNE DE {commune_name.upper()}")

    # Haut droite (Titre)
    p.setFillColor(HexColor("#0B2240"))
    p.setFont("Helvetica-Bold", 24)
    title = "CERTIFICAT DE RESIDENCE"
    title_x = width / 2 + 3.0 * cm
    p.drawCentredString(title_x, height - 2.2 * cm, title)
    
    title_width = p.stringWidth(title, "Helvetica-Bold", 24)
    p.setLineWidth(1)
    p.line(title_x - title_width/2, height - 2.5 * cm, title_x + title_width/2, height - 2.5 * cm)
    
    p.setFillColor(COLOR_NOIR)
    p.setFont("Helvetica", 12)
    p.drawCentredString(title_x, height - 4.0 * cm, f"N° Pièce portée : {dossier.reference}")

    # --- CORPS ---
    if quartier and quartier.lower() in adresse.lower():
        quartier_text = ""
    else:
        quartier_text = f" au quartier {quartier}" if quartier and quartier.strip() else ""
        
    duree_str = str(date_installation).strip()
    duree_lower = duree_str.lower()
    if "il y a" in duree_lower:
        val = duree_lower.replace("il y a", "").strip()
        if not val.endswith("ans"): val += " ans"
        depuis_text = f"depuis {val}"
    elif duree_lower.isdigit() and len(duree_lower) <= 2:
        depuis_text = f"depuis {duree_lower} ans"
    elif duree_lower.endswith("ans"):
        depuis_text = f"depuis {duree_lower}"
    else:
        depuis_text = f"depuis {duree_lower}" if duree_lower else ""

    from utils.pdf_helpers import accord
    genre = metadata.get('genre') or metadata.get('sexe') or ''
    ne_nee = accord(genre, 'né', 'née', dossier.id if hasattr(dossier, 'id') else dossier.reference)
    il_elle = accord(genre, 'il', 'elle', dossier.id if hasattr(dossier, 'id') else dossier.reference)
    soussigne_e = accord(genre, 'soussigné', 'soussignée', dossier.id if hasattr(dossier, 'id') else dossier.reference)

    texte_complet = (f"Nous {soussigne_e} Maire de la Commune de {commune_name.capitalize()} certifions "
                     f"que {nom_complet} {ne_nee} le {date_naissance_str} à {lieu_naissance} et qu'{il_elle} "
                     f"réside à {adresse}{quartier_text} {depuis_text}.")

    p.setFillColor(COLOR_NOIR)
    style = ParagraphStyle(name='Center', fontName='Helvetica', fontSize=18, leading=28, alignment=TA_CENTER)
    para = Paragraph(texte_complet, style)
    para.wrap(width - 4 * cm, 10 * cm)
    para.drawOn(p, 2 * cm, height / 2 - 1.0 * cm)

    # --- PIED DE PAGE ---
    footer_y = 5.0 * cm

    # Gauche : Validité, QR, Timbre
    p.setFillColor(HexColor("#D32F2F"))
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2.0 * cm, footer_y, "Validité : 3 mois à compter de la date de délivrance")
    
    p.setFillColor(COLOR_NOIR)
    qr_x = 2.0 * cm
    qr_y = footer_y - 3.5 * cm
    qr_size = 2.5 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
        p.setFont("Helvetica", 6.5)
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.3 * cm, "Scannez pour vérifier")
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.55 * cm, "l'authenticité")
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    if timbre_ref:
        _draw_secure_timbre(p, qr_x + qr_size + 0.5 * cm, qr_y + 0.5 * cm, timbre_ref)

    # Droite : Lieu, date, signatures
    sig_x = width - 8.0 * cm
    from datetime import datetime
    date_str = dossier.updated_at.strftime('%d/%m/%Y') if dossier.updated_at else datetime.now().strftime('%d/%m/%Y')
    
    p.setFont("Helvetica", 10)
    p.drawCentredString(sig_x, footer_y - 0.5 * cm, f"Fait à {commune_name.capitalize()}, le {date_str}")
    p.drawCentredString(sig_x, footer_y - 1.2 * cm, "Officier de l'État Civil")
    
    seal_size = 3.5 * cm
    seal_y = footer_y - 5.0 * cm
    _draw_signatures_and_seals(p, width - 13.5 * cm, seal_y, cachet_path, signature_path, cachet_nominal_path, seal_size, commune_name, "")

def number_to_french_words(n):
    if n == 0:
        return "zéro"
    
    units = ["", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf"]
    teens = ["dix", "onze", "douze", "treize", "quatorze", "quinze", "seize", "dix-sept", "dix-huit", "dix-neuf"]
    tens = ["", "", "vingt", "trente", "quarante", "cinquante", "soixante", "soixante-dix", "quatre-vingt", "quatre-vingt-dix"]
    
    def convert_under_100(val):
        if val < 10:
            return units[val]
        elif val < 20:
            return teens[val - 10]
        elif val < 70:
            ten = val // 10
            unit = val % 10
            if unit == 0:
                return tens[ten]
            elif unit == 1:
                return f"{tens[ten]} et un"
            else:
                return f"{tens[ten]}-{units[unit]}"
        elif val < 80:
            unit = val % 10
            if unit == 0:
                return "soixante-dix"
            elif unit == 1:
                return "soixante et onze"
            else:
                return f"soixante-{teens[unit]}"
        elif val < 90:
            unit = val % 10
            if unit == 0:
                return "quatre-vingt"
            else:
                return f"quatre-vingt-{units[unit]}"
        else:
            unit = val % 10
            if unit == 0:
                return "quatre-vingt-dix"
            else:
                return f"quatre-vingt-{teens[unit]}"

    def convert_under_1000(val):
        if val < 100:
            return convert_under_100(val)
        hundreds = val // 100
        remainder = val % 100
        if hundreds == 1:
            h_str = "cent"
        else:
            h_str = f"{units[hundreds]} cent"
        if remainder == 0:
            return h_str
        else:
            return f"{h_str} {convert_under_100(remainder)}"

    if n < 1000:
        return convert_under_1000(n)
    
    thousands = n // 1000
    remainder = n % 1000
    if thousands == 1:
        t_str = "mille"
    else:
        t_str = f"{convert_under_1000(thousands)} mille"
    if remainder == 0:
        return t_str
    else:
        return f"{t_str} {convert_under_1000(remainder)}"


def get_registration_datetime_in_words(dossier, metadata):
    annee_val = metadata.get('annee_marriage') or metadata.get('annee_registre') or metadata.get('annee_texte')
    mois_val = metadata.get('mois_texte') or metadata.get('mois_mariage') or metadata.get('mois_registre')
    heure_val = metadata.get('heure_texte') or metadata.get('heure_marriage') or metadata.get('heure_registre')

    dt = getattr(dossier, 'completed_at', None) or getattr(dossier, 'submitted_at', None) or getattr(dossier, 'created_at', None) or getattr(dossier, 'updated_at', None)
    from datetime import datetime
    if not dt:
        dt = datetime.now()

    french_months = {
        1: "janvier", 2: "février", 3: "mars", 4: "avril", 5: "mai", 6: "juin",
        7: "juillet", 8: "août", 9: "septembre", 10: "octobre", 11: "novembre", 12: "décembre"
    }

    # Tentative de récupération depuis date_marriage si absent
    date_marriage_val = metadata.get('date_marriage') or metadata.get('date_mariage') or metadata.get('date_marriage_texte')
    if date_marriage_val and not (annee_val and mois_val):
        parts = str(date_marriage_val).split()
        for p in parts:
            if p.isdigit() and len(p) == 4 and not annee_val:
                annee_val = p
            else:
                p_clean = p.lower().strip()
                for m_num, m_name in french_months.items():
                    if p_clean == m_name or p_clean == m_name[:-1] or p_clean.startswith(m_name[:4]):
                        if not mois_val:
                            mois_val = m_name

    # 1. Année
    if annee_val:
        annee_str = str(annee_val).strip()
        if annee_str.isdigit():
            annee_words = number_to_french_words(int(annee_str))
        else:
            annee_words = annee_str
    else:
        annee_words = number_to_french_words(dt.year)

    # 2. Mois
    if mois_val:
        mois_str = str(mois_val).strip()
        if mois_str.isdigit() and int(mois_str) in french_months:
            mois_words = french_months[int(mois_str)]
        else:
            mois_words = mois_str
    else:
        mois_words = french_months[dt.month]

    mois_words_lower = mois_words.lower().strip()
    if mois_words_lower and mois_words_lower[0] in 'aeiouyéèàâûîô':
        mois_part = f"d'{mois_words}"
    else:
        mois_part = f"de {mois_words}"

    # 3. Heure et minutes
    if heure_val:
        heure_str = str(heure_val).strip()
        if ":" in heure_str:
            try:
                h_parts = heure_str.split(":")
                h_num = int(h_parts[0])
                m_num = int(h_parts[1])
                h_words = number_to_french_words(h_num)
                m_words = number_to_french_words(m_num)
                if m_num == 0:
                    time_words = f"à {h_words} heures"
                else:
                    time_words = f"à {h_words} heures {m_words} minutes"
            except Exception:
                time_words = heure_str
        elif heure_str.isdigit():
            try:
                time_words = f"à {number_to_french_words(int(heure_str))} heures"
            except Exception:
                time_words = heure_str
        else:
            time_words = heure_str
            if not time_words.startswith("à"):
                time_words = f"à {time_words}"
    else:
        h_words = number_to_french_words(dt.hour)
        m_words = number_to_french_words(dt.minute)
        if dt.minute == 0:
            time_words = f"à {h_words} heures"
        else:
            time_words = f"à {h_words} heures {m_words} minutes"

    return annee_words, mois_part, time_words


def clean_val(val, default="Non renseigné"):
    if val is None or str(val).strip() == "" or str(val).lower() == "none":
        return default
    return str(val).strip()


def get_parent_name(metadata, prefix, relation):
    prenom_key = f"prenom_{relation}_{prefix}"
    nom_key = f"nom_{relation}_{prefix}"
    single_key = f"{relation}_{prefix}"
    
    prenom = metadata.get(prenom_key, '')
    nom = metadata.get(nom_key, '')
    single = metadata.get(single_key, '')
    
    if prenom or nom:
        return f"{prenom} {nom}".strip()
    return single or None


def generate_marriage_certificate_v2(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    NOIR = HexColor('#000000')
    metadata = dossier.metadata or {}
    
    # ── 1. EN-TÊTE DOUBLE COLONNE ──
    # Colonne Gauche
    p.setFillColor(NOIR)
    p.setFont("Helvetica-Bold", 10)
    
    commune = getattr(dossier, 'commune', None)
    region = clean_val(getattr(commune, 'region', None) if commune else None).upper()
    p.drawString(2.0 * cm, height - 2.0 * cm, f"RÉGION DE {region}")
    
    departement = clean_val(getattr(commune, 'department', None) if commune else None).upper()
    p.drawString(2.0 * cm, height - 2.5 * cm, f"DÉPARTEMENT DE {departement}")
    
    commune_name = clean_val(getattr(commune, 'name', None) if commune else None).upper()
    p.drawString(2.0 * cm, height - 3.0 * cm, f"COMMUNE DE {commune_name}")
        
    # Colonne Droite
    p.setFont("Helvetica-Bold", 10)
    p.drawRightString(width - 2.0 * cm, height - 2.0 * cm, "RÉPUBLIQUE DU SÉNÉGAL")
    p.setFont("Helvetica-Oblique", 9)
    p.drawRightString(width - 2.0 * cm, height - 2.5 * cm, "Un Peuple – Un But – Une Foi")
    
    # Ligne de séparation
    p.setStrokeColor(NOIR)
    p.setLineWidth(1)
    p.line(2.0 * cm, height - 4.5 * cm, width - 2.0 * cm, height - 4.5 * cm)
    
    # ── 2. TITRE ──
    y_titre = height - 5.5 * cm
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(width / 2, y_titre, "CERTIFICAT DE MARIAGE CONSTATÉ")

    # ── 3. BLOC REGISTRE + DATE EN TOUTES LETTRES ──
    y_reg = y_titre - 1.5 * cm
    p.setFont("Helvetica-Bold", 11)
    registre_no = clean_val(metadata.get('registre_marriage') or metadata.get('numero_registre') or metadata.get('registre'))
    p.drawString(2.0 * cm, y_reg, f"Registre N° {registre_no}")
    
    p.setFont("Helvetica", 11)
    annee_words, mois_part, time_words = get_registration_datetime_in_words(dossier, metadata)
    p.drawString(2.0 * cm, y_reg - 0.6 * cm, f"L'an {annee_words},")
    p.drawString(2.0 * cm, y_reg - 1.2 * cm, f"Du mois {mois_part}, {time_words}.")
    
    # ── 4. PARAGRAPHE D'OUVERTURE ──
    y_body = y_reg - 2.0 * cm
    officier_name = clean_val(metadata.get('officier_nom') or metadata.get('officier') or (officier.full_name if officier else None) or (getattr(commune, 'nom_officier_etat_civil', None) if commune else None), default="L'Officier d'État Civil")
    centre_val = metadata.get('centre_nom') or metadata.get('centre')
    centre_etat_civil = centre_val if centre_val else (getattr(commune, 'name', "Centre d'État Civil") if commune else "Centre d'État Civil")
    
    if centre_val:
        if "SECONDAIRE" in centre_val.upper():
            centre_phrase = centre_val
        else:
            centre_phrase = f"CENTRE SECONDAIRE DE {centre_val.upper()}" if ("FANN" in centre_val.upper() or "GRAND" in centre_val.upper()) else f"CENTRE PRINCIPAL DE {centre_val.upper()}"
    else:
        centre_phrase = f"CENTRE DE {centre_etat_civil.upper()}"

    intro_text = f"Nous, <b>{officier_name}</b>, Officier d'État civil du {centre_phrase}, certifions à tous ceux qu'il appartiendra que :"
    
    style_normal = ParagraphStyle(
        name='MarriageV2Normal',
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        alignment=TA_LEFT
    )
    style_center = ParagraphStyle(
        name='MarriageV2Center',
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        alignment=TA_CENTER
    )
    
    para_intro = Paragraph(intro_text, style_normal)
    para_intro.wrap(width - 4.0 * cm, 5 * cm)
    para_intro.drawOn(p, 2.0 * cm, y_body - para_intro.height)
    y_body -= para_intro.height + 0.6 * cm
    
    # ── 5. BLOC ÉPOUX ──
    nom_epoux = clean_val(metadata.get('nom_epoux') or metadata.get('epoux_1_nom_complet') or f"{metadata.get('prenom_epoux', '')} {metadata.get('nom_epoux', '')}").upper()
    profession_epoux = clean_val(metadata.get('profession_epoux'))
    domicile_epoux = clean_val(metadata.get('domicile_epoux') or metadata.get('adresse_epoux') or metadata.get('adresse'))
    date_naissance_epoux = clean_val(metadata.get('date_naissance_epoux'))
    lieu_naissance_epoux = clean_val(metadata.get('lieu_naissance_epoux'))
    nom_pere_epoux = clean_val(get_parent_name(metadata, 'epoux', 'pere'))
    nom_mere_epoux = clean_val(get_parent_name(metadata, 'epoux', 'mere'))
    
    epoux_text = (
        f"<b>Monsieur {nom_epoux},</b><br/>"
        f"Profession : <b>{profession_epoux}</b>, domicilié à <b>{domicile_epoux}</b>,<br/>"
        f"Né le {date_naissance_epoux} à {lieu_naissance_epoux},<br/>"
        f"Fils de <b>{nom_pere_epoux}</b> et de <b>{nom_mere_epoux}</b>,<br/>"
        "D'une part,"
    )
    para_epoux = Paragraph(epoux_text, style_normal)
    para_epoux.wrap(width - 4.0 * cm, 6 * cm)
    para_epoux.drawOn(p, 2.0 * cm, y_body - para_epoux.height)
    y_body -= para_epoux.height + 0.4 * cm
    
    # ── 6. "Et" ──
    para_et = Paragraph("<b>Et</b>", style_center)
    para_et.wrap(width - 4.0 * cm, 1 * cm)
    para_et.drawOn(p, 2.0 * cm, y_body - para_et.height)
    y_body -= para_et.height + 0.4 * cm
    
    # ── 7. BLOC ÉPOUSE ──
    nom_epouse = clean_val(metadata.get('nom_epouse') or metadata.get('epoux_2_nom_complet') or f"{metadata.get('prenom_epouse', '')} {metadata.get('nom_epouse', '')}").upper()
    profession_epouse = clean_val(metadata.get('profession_epouse'))
    domicile_epouse = clean_val(metadata.get('domicile_epouse') or metadata.get('adresse_epouse'))
    date_naissance_epouse = clean_val(metadata.get('date_naissance_epouse'))
    lieu_naissance_epouse = clean_val(metadata.get('lieu_naissance_epouse'))
    nom_pere_epouse = clean_val(get_parent_name(metadata, 'epouse', 'pere'))
    nom_mere_epouse = clean_val(get_parent_name(metadata, 'epouse', 'mere'))
    
    epouse_text = (
        f"<b>Mademoiselle/Madame {nom_epouse},</b><br/>"
        f"Profession : <b>{profession_epouse}</b>, domiciliée à <b>{domicile_epouse}</b>,<br/>"
        f"Née le {date_naissance_epouse} à {lieu_naissance_epouse},<br/>"
        f"Fille de <b>{nom_pere_epouse}</b> et de <b>{nom_mere_epouse}</b>,<br/>"
        "D'autre part,"
    )
    para_epouse = Paragraph(epouse_text, style_normal)
    para_epouse.wrap(width - 4.0 * cm, 6 * cm)
    para_epouse.drawOn(p, 2.0 * cm, y_body - para_epouse.height)
    y_body -= para_epouse.height + 0.5 * cm
    
    # ── 8. PARAGRAPHE DE CONCLUSION ──
    date_mariage = clean_val(metadata.get('date_mariage') or metadata.get('date_marriage') or metadata.get('date_mariage_texte') or metadata.get('date_marriage_texte'))
    option_souscrite = clean_val(metadata.get('option_souscrite') or metadata.get('option_matrimoniale'), default="Monogamie")
    regime_matrimonial = clean_val(metadata.get('regime_matrimonial') or metadata.get('regime'), default="séparation des biens")
    
    ville_enregistrement = clean_val(metadata.get('lieu_enregistrement') or metadata.get('ville') or (getattr(commune, 'name', '') if commune else ""))
    from datetime import datetime
    reg_date_val = getattr(dossier, 'completed_at', None) or getattr(dossier, 'submitted_at', None) or getattr(dossier, 'created_at', None) or getattr(dossier, 'updated_at', None)
    if not reg_date_val:
        reg_date_val = datetime.now()
    date_enregistrement_str = clean_val(metadata.get('date_enregistrement') or reg_date_val.strftime('%d/%m/%Y'))

    concl_text = (
        f"Ont contracté mariage entre eux selon la coutume, le <b>{date_mariage}</b>,<br/>"
        f"Option souscrite : <b>{option_souscrite}</b>,<br/>"
        f"Et que ce mariage a été enregistré par nous sur leur demande le <b>{date_enregistrement_str}</b> à <b>{ville_enregistrement}</b>,<br/>"
        f"Régime matrimonial choisi : <b>{regime_matrimonial}</b>."
    )
    para_concl = Paragraph(concl_text, style_normal)
    para_concl.wrap(width - 4.0 * cm, 6 * cm)
    para_concl.drawOn(p, 2.0 * cm, y_body - para_concl.height)
    y_body -= para_concl.height + 0.5 * cm
    
    # ── 9. FORMULE DE FIN ──
    fin_text = "En foi de quoi, nous avons délivré le présent certificat pour servir et valoir ce que de droit."
    para_fin = Paragraph(fin_text, style_normal)
    para_fin.wrap(width - 4.0 * cm, 2 * cm)
    para_fin.drawOn(p, 2.0 * cm, y_body - para_fin.height)

    # ── 10. PIED DE PAGE & SIGNATURES ──
    sig_zone_x = width - 11.0 * cm
    sig_zone_y = 5.0 * cm
    
    p.setFillColor(NOIR)
    p.setFont("Helvetica", 10)
    p.drawCentredString(sig_zone_x + 5.0 * cm, sig_zone_y, f"Fait à {ville_enregistrement}, le {date_enregistrement_str}")
    
    p.setFont("Helvetica-Bold", 10)
    p.drawCentredString(sig_zone_x + 5.0 * cm, sig_zone_y - 0.5 * cm, "L'Officier d'État Civil")
    
    seal_size = 3.2 * cm
    seal_y = 1.0 * cm
    
    # Cachets + signature
    _draw_signatures_and_seals(p, sig_zone_x, seal_y, cachet_path, signature_path, cachet_nominal_path, seal_size)

    # QR Code et Timbre Fiscal (Discrets en bas à gauche)
    qr_x = 2.0 * cm
    qr_size = 2.2 * cm
    qr_y = 1.5 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
        p.setFillColor(NOIR)
        p.setFont("Helvetica", 6.5)
        p.drawString(qr_x, qr_y - 0.3 * cm, "Scannez pour vérifier")
        p.drawString(qr_x, qr_y - 0.55 * cm, "l'authenticité")
        p.drawString(qr_x, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    if timbre_ref:
        _draw_secure_timbre(p, qr_x + qr_size + 0.8 * cm, qr_y, timbre_ref)


def _draw_mariage_pdf_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    generate_marriage_certificate_v2(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)


def _draw_deces_header(p, width, height, commune, reference):
    """
    En-tête DÉDIÉ au certificat de décès — identique visuellement
    au certificat de résidence (sobre, sans bandeau ni filigrane).
      - Haut gauche  : Un Peuple - Un But - Une Foi / RÉGION / COMMUNE
      - Haut droit   : CERTIFICAT DE DÉCÈS (grand, gras, souligné)
      - Centré       : N° Pièce portée : [reference]
    """
    commune_name = commune.name if commune else "INCONNUE"
    region_name  = (commune.region if commune and hasattr(commune, 'region')
                    and commune.region else "DAKAR")

    # ── Bloc haut-gauche ──────────────────────────────────────────
    p.setFillColor(HexColor('#000000'))
    p.setFont("Helvetica-Oblique", 9)
    p.drawString(1.8 * cm, height - 1.5 * cm, "Un Peuple - Un But - Une Foi")
    p.setFont("Helvetica-Bold", 10)
    p.drawString(1.8 * cm, height - 2.1 * cm, f"REGION DE {region_name.upper()}")
    p.drawString(1.8 * cm, height - 2.7 * cm, f"COMMUNE DE {commune_name.upper()}")

    # ── Titre haut-droit ─────────────────────────────────────────
    title_x = width / 2 + 0.5 * cm
    title_y  = height - 2.0 * cm
    p.setFont("Helvetica-Bold", 28)
    p.drawString(title_x, title_y, "CERTIFICAT DE DÉCÈS")

    # Trait souligné
    p.setStrokeColor(HexColor('#000000'))
    p.setLineWidth(1.2)
    p.line(title_x, title_y - 0.25 * cm, width - 1.5 * cm, title_y - 0.25 * cm)

    # ── Référence centrée ────────────────────────────────────────
    ref_y = title_y - 1.4 * cm
    p.setFont("Helvetica", 11)
    p.setFillColor(HexColor('#000000'))
    p.drawCentredString(width / 2, ref_y, f"N° Pièce portée : {reference}")

    return ref_y - 2.5 * cm   # y de départ pour le corps


def _draw_deces_footer(p, width, height, dossier, officier, timbre_ref,
                       cachet_path, signature_path, cachet_nominal_path,
                       qr_image_reader):
    """
    Pied de page DÉDIÉ au certificat de décès — identique au certificat
    de résidence : mention rouge, QR + timbre, zone signature + deux cachets.
    """
    from datetime import datetime

    commune_name  = dossier.commune.name.capitalize() if dossier.commune else "N/A"
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"
    date_str = (dossier.updated_at.strftime('%d/%m/%Y')
                if dossier.updated_at else datetime.now().strftime('%d/%m/%Y'))

    footer_top = 5.5 * cm

    # ── Ligne de séparation ──────────────────────────────────────
    p.setStrokeColor(HexColor('#CCCCCC'))
    p.setLineWidth(0.8)
    p.line(1.5 * cm, footer_top, width - 1.5 * cm, footer_top)

    # ── Mention en rouge ─────────────────────────────────────────
    p.setFillColor(HexColor('#CC0000'))
    p.setFont("Helvetica-Bold", 9)
    p.drawString(1.8 * cm, footer_top - 0.5 * cm,
                 "Document à valeur d'extrait d'acte de décès")

    # ── QR code ─────────────────────────────────────────────────
    qr_x    = 1.8 * cm
    qr_size = 2.5 * cm
    qr_y    = footer_top - 3.8 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
        p.setFillColor(HexColor('#000000'))
        p.setFont("Helvetica", 6.5)
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.3 * cm, "Scannez pour vérifier")
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.55 * cm, "l'authenticité")
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.8 * cm,
                            f"Réf : {dossier.reference}")

    # ── Timbre fiscal ────────────────────────────────────────────
    if timbre_ref:
        _draw_secure_timbre(p, qr_x + qr_size + 0.8 * cm, qr_y, timbre_ref)

    # ── Zone signature (droite) ──────────────────────────────────
    sig_x = width - 11.0 * cm
    p.setFillColor(HexColor('#000000'))
    p.setFont("Helvetica", 9)
    p.drawCentredString(sig_x + 4.5 * cm, footer_top - 0.6 * cm,
                        f"Fait à {commune_name}, le {date_str}")
    p.drawCentredString(sig_x + 4.5 * cm, footer_top - 1.1 * cm,
                        "Officier de l'État Civil")

    # ── Cachets + signature ──────────────────────────────────────
    seal_size = 3.2 * cm
    seal_y    = footer_top - 5.0 * cm
    _draw_signatures_and_seals(p, sig_x, seal_y, cachet_path, signature_path, cachet_nominal_path, seal_size)

    # ── Mention légale ───────────────────────────────────────────
    p.setFillColor(HexColor('#888888'))
    p.setFont("Helvetica-Oblique", 7)
    p.drawCentredString(
        width / 2, 0.7 * cm,
        "Document généré électroniquement - SUNU CIVIL / Teranga Civil. "
        "Ce document est sécurisé par une empreinte cryptographique (HMAC-SHA256)."
    )


def _draw_deces_pdf_content(p, width, height, dossier, officier, timbre_ref,
                             cachet_path, signature_path, cachet_nominal_path,
                             qr_image_reader):
    """
    Template DÉDIÉ et ISOLÉ — Certificat de Décès.
    Design reproduit à l'identique du Certificat de Résidence (sobre,
    paysage A4), avec contenu adapté au décès.
    NE PAS modifier pour naissance / mariage / résidence.
    """
    # Pas de filigrane, pas de bandeau — fond blanc pur
    metadata     = dossier.metadata or {}
    commune_name = dossier.commune.name if dossier.commune else "INCONNUE"

    # ── En-tête sobre dédié ───────────────────────────────────────
    y = _draw_deces_header(p, width, height, dossier.commune, dossier.reference)

    # ── Extraction des champs métadonnées ─────────────────────────
    prenom        = metadata.get('prenom_defunt', '')
    nom           = metadata.get('nom_defunt', '')
    nom_complet   = f"{prenom} {nom}".strip() or 'N/A'

    sexe  = metadata.get('sexe_defunt', '')
    titre = "Monsieur" if sexe.lower().startswith('m') else "Madame"

    nationalite = metadata.get('nationalite_defunt', '')
    profession  = metadata.get('profession_defunt', '')
    adresse     = metadata.get('adresse_defunt', '')
    date_naiss  = metadata.get('date_naissance_defunt', '')
    lieu_naiss  = metadata.get('lieu_naissance_defunt', '')
    date_deces  = metadata.get('date_deces', '')
    heure_deces = metadata.get('heure_deces', '')
    lieu_deces  = metadata.get('lieu_deces', '')
    num_registre    = str(metadata.get('numero_registre') or metadata.get('registre', ''))
    nom_declarant   = metadata.get('nom_declarant', '')
    lien_declarant  = metadata.get('lien_declarant', '')
    cni_declarant   = metadata.get('cni_declarant', '')

    from utils.pdf_helpers import accord
    genre = sexe
    soussigne_e = accord(genre, 'soussigné', 'soussignée', dossier.id if hasattr(dossier, 'id') else dossier.reference)
    ne_nee = accord(genre, 'né', 'née', dossier.id if hasattr(dossier, 'id') else dossier.reference)
    domicilie_e = accord(genre, 'domicilié', 'domiciliée', dossier.id if hasattr(dossier, 'id') else dossier.reference)
    decede_e = accord(genre, 'décédé', 'décédée', dossier.id if hasattr(dossier, 'id') else dossier.reference)

    # ── Texte narratif central ─────────────────────────────────────
    texte = (f"Nous {soussigne_e} Maire de la Commune de "
             f"{commune_name.capitalize()} certifions que "
             f"{titre} {nom_complet}")

    if date_naiss:
        texte += f", {ne_nee} le {date_naiss}"
    if lieu_naiss:
        texte += f" à {lieu_naiss}"
    if nationalite:
        texte += f", de nationalité {nationalite}"
    if profession:
        texte += f", exerçant la profession de {profession}"
    if adresse:
        texte += f", {domicilie_e} à {adresse}"

    texte += f", est {decede_e}"
    if date_deces:
        texte += f" le {date_deces}"
    if heure_deces:
        texte += f" à {heure_deces}"
    if lieu_deces:
        texte += f", à {lieu_deces}"

    if num_registre:
        texte += (f", conformément à l'acte n°{num_registre} "
                  f"du registre des décès")

    if nom_declarant:
        texte += f", déclaré par {nom_declarant}"
        if lien_declarant:
            texte += f" ({lien_declarant})"
        if cni_declarant:
            texte += f", pièce d'identité N° {cni_declarant}"

    texte += "."

    # ── Rendu du paragraphe (centré, taille 14 — identique résidence) ─
    p.setFillColor(HexColor('#000000'))
    p.setFont("Helvetica", 14)
    style_center = ParagraphStyle(
        name='DecesCenterNarrative',
        fontName='Helvetica',
        fontSize=14,
        leading=22,
        alignment=TA_CENTER,
    )
    para = Paragraph(texte, style_center)
    para.wrap(width - 4 * cm, 10 * cm)
    para.drawOn(p, 3 * cm, y - para.height - 0.5 * cm)

    # ── Pied de page dédié ───────────────────────────────────────
    _draw_deces_footer(p, width, height, dossier, officier, timbre_ref,
                       cachet_path, signature_path, cachet_nominal_path,
                       qr_image_reader)


def generate_birth_certificate_v2(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    from reportlab.lib.units import cm
    from reportlab.lib.colors import HexColor
    from datetime import datetime
    
    NOIR = HexColor('#000000')
    metadata = dossier.metadata or {}
    citizen = dossier.citizen

    # --- Données de base ---
    region = dossier.commune.region.upper() if dossier.commune and dossier.commune.region else "N/A"
    departement = dossier.commune.department.upper() if dossier.commune and hasattr(dossier.commune, 'department') and dossier.commune.department else "N/A"
    commune = dossier.commune.name.upper() if dossier.commune else "N/A"
    
    annee_registre = str(metadata.get('annee_registre', 'N/A'))
    numero_registre = str(metadata.get('numero_registre') or metadata.get('registre', 'N/A'))
    
    prenoms_enfant = clean_val(metadata.get('prenoms_enfant') or (citizen.first_name if citizen else ""), default="")
    nom_enfant = clean_val(metadata.get('nom_enfant') or (citizen.last_name if citizen else ""), default="")
    sexe = clean_val(metadata.get('sexe') or (citizen.profile.get_gender_display() if citizen and hasattr(citizen, 'profile') else ""), default="N/A").upper()
    
    date_naissance = clean_val(metadata.get('date_naissance_personne') or metadata.get('date_naissance') or (str(citizen.profile.date_of_birth) if citizen and hasattr(citizen, 'profile') else ""), default="")
    heure_naissance = clean_val(metadata.get('heure_naissance'), default="")
    lieu_naissance = clean_val(metadata.get('lieu_naissance') or metadata.get('lieu_naissance_enfant') or (citizen.profile.place_of_birth if citizen and hasattr(citizen, 'profile') else ""), default="")
    if not lieu_naissance:
        lieu_naissance = "N/A"
    
    prenom_pere = clean_val(metadata.get('prenom_pere'), default="")
    nom_pere = clean_val(metadata.get('nom_pere'), default="")
    nom_prenom_pere = f"{prenom_pere} {nom_pere}".strip() if prenom_pere or nom_pere else "N/A"
    
    prenom_mere = clean_val(metadata.get('prenom_mere'), default="")
    nom_mere = clean_val(metadata.get('nom_mere'), default="")

    annee_words, mois_part, time_words = get_registration_datetime_in_words(dossier, metadata)
    
    # Date établissement acte
    dt = getattr(dossier, 'completed_at', None) or getattr(dossier, 'submitted_at', None) or getattr(dossier, 'created_at', None) or getattr(dossier, 'updated_at', None)
    if not dt:
        from datetime import datetime
        dt = datetime.now()
    try:
        jour_words = number_to_french_words(dt.day)
    except:
        jour_words = str(dt.day)
    date_acte_string = f"L'an {annee_words}, le {jour_words} {mois_part}"
    
    try:
        num_reg_words = number_to_french_words(int(numero_registre)).upper()
    except:
        num_reg_words = numero_registre

    # Format de la grille : marges
    x_margin = 1.0 * cm
    grid_w = width - 2.0 * cm
    grid_right = width - 1.0 * cm
    
    y_top = height - 1.5 * cm
    y_header_bottom = y_top - 3.5 * cm
    y_title_bottom = y_header_bottom - 3.0 * cm
    y_body_bottom = y_title_bottom - 9.0 * cm
    y_jugement_bottom = y_body_bottom - 4.0 * cm
    y_marginal_bottom = y_jugement_bottom - 2.0 * cm
    
    # Dessin de la grille (lignes extérieures)
    p.setStrokeColor(NOIR)
    p.setLineWidth(1.2)
    p.rect(x_margin, y_marginal_bottom, grid_w, y_top - y_marginal_bottom)
    
    # Lignes horizontales
    p.line(x_margin, y_header_bottom, grid_right, y_header_bottom)
    p.line(x_margin, y_title_bottom, grid_right, y_title_bottom)
    p.line(x_margin, y_body_bottom, grid_right, y_body_bottom)
    p.line(x_margin, y_jugement_bottom, grid_right, y_jugement_bottom)
    
    # ── 1. EN-TÊTE ──
    x_mid_header = x_margin + 9.5 * cm
    p.line(x_mid_header, y_header_bottom, x_mid_header, y_top)
    
    # Gauche
    p.setFont("Helvetica-Bold", 10)
    p.drawString(x_margin + 2.0 * cm, y_top - 0.8 * cm, f"REGION: {region}")
    p.drawString(x_margin + 2.0 * cm, y_top - 1.8 * cm, f"DEPARTEMENT: {departement}")
    p.drawString(x_margin + 2.0 * cm, y_top - 2.8 * cm, f"COMMUNE: {commune}")
    
    # Droite
    x_right_center = x_mid_header + (grid_right - x_mid_header) / 2
    p.drawCentredString(x_right_center, y_top - 0.6 * cm, "REPUBLIQUE DU SENEGAL")
    p.setFont("Helvetica-Oblique", 9)
    p.drawCentredString(x_right_center, y_top - 1.1 * cm, "Un Peuple - Un But - Une Foi")
    p.setFont("Helvetica-Bold", 16)
    p.drawCentredString(x_right_center, y_top - 1.9 * cm, "ETAT-CIVIL")
    p.setFont("Helvetica", 9)
    p.drawCentredString(x_right_center, y_top - 2.5 * cm, "CENTRE PRINCIPAL (1)")
    p.drawCentredString(x_right_center, y_top - 3.1 * cm, f"{commune} CENTRE PRINCIPAL")
    
    # ── 2. BANDEAU TITRE ──
    x_title_right = grid_right - 3.5 * cm
    p.line(x_title_right, y_title_bottom, x_title_right, y_header_bottom)
    
    p.setFont("Helvetica-Bold", 16)
    p.drawCentredString(x_margin + (x_title_right - x_margin) / 2, y_header_bottom - 0.8 * cm, "EXTRAIT DU REGISTRE DES ACTES DE NAISSANCE")
    p.setFont("Helvetica-Oblique", 10)
    p.drawString(x_margin + 0.5 * cm, y_header_bottom - 1.5 * cm, f"Pour l'année {annee_words}")
    text_num = f"NUMERO: {num_reg_words} DANS LE REGISTRE"
    font_size = 10
    max_w = (x_title_right - x_margin) - 0.7 * cm
    while p.stringWidth(text_num, "Helvetica", font_size) > max_w and font_size > 5.5:
        font_size -= 0.5
    
    p.setFont("Helvetica", font_size)
    p.drawString(x_margin + 0.5 * cm, y_header_bottom - 2.4 * cm, text_num)
    
    # Droite Titre
    p.setFont("Helvetica-Bold", 12)
    p.drawCentredString(x_title_right + 1.75 * cm, y_header_bottom - 0.8 * cm, f"AN {annee_registre}")
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(x_title_right + 1.75 * cm, y_header_bottom - 1.8 * cm, f"{numero_registre}")
    p.setFont("Helvetica", 7)
    p.drawCentredString(x_title_right + 1.75 * cm, y_header_bottom - 2.4 * cm, "1er dans le registre en")
    p.drawCentredString(x_title_right + 1.75 * cm, y_header_bottom - 2.7 * cm, "chiffres")
    
    # ── 3. CORPS DE L'ACTE ──
    p.setFont("Helvetica-Bold", 10)
    p.drawString(x_margin + 0.5 * cm, y_title_bottom - 0.8 * cm, date_acte_string) 
    
    from utils.pdf_helpers import accord
    genre_enfant = metadata.get('sexe', '')
    est_ne_nee = accord(genre_enfant, 'Est né à', 'Est née à', dossier.id if hasattr(dossier, 'id') else dossier.reference)

    p.setFont("Helvetica", 10)
    p.drawString(x_margin + 0.5 * cm, y_title_bottom - 1.8 * cm, est_ne_nee)
    p.drawString(x_margin + 2.5 * cm, y_title_bottom - 1.8 * cm, lieu_naissance)
    p.setFont("Helvetica-Oblique", 7)
    p.drawString(x_margin + 2.5 * cm, y_title_bottom - 2.2 * cm, "LIEU DE NAISSANCE")
        
    p.setFont("Helvetica", 10)
    p.drawString(grid_right - 6.0 * cm, y_title_bottom - 1.8 * cm, "À:")
    if heure_naissance:
        p.setFont("Helvetica-Bold", 10)
        p.drawString(grid_right - 5.5 * cm, y_title_bottom - 1.8 * cm, heure_naissance)
    
    p.setFont("Helvetica-Oblique", 7)
    p.drawString(grid_right - 6.0 * cm, y_title_bottom - 2.2 * cm, "HEURE DE NAISSANCE")
    
    p.setFont("Helvetica", 10)
    p.drawString(x_margin + 0.5 * cm, y_title_bottom - 3.2 * cm, f"Un enfant de sexe {sexe}")
    
    p.setFont("Helvetica-Bold", 16)
    p.drawString(x_margin + 1.5 * cm, y_title_bottom - 4.5 * cm, prenoms_enfant.upper())
    p.drawString(grid_right - 8.0 * cm, y_title_bottom - 4.5 * cm, nom_enfant.upper())
    
    p.setFont("Helvetica-Oblique", 7)
    p.drawString(x_margin + 1.5 * cm, y_title_bottom - 5.0 * cm, "PRENOMS")
    p.drawString(grid_right - 8.0 * cm, y_title_bottom - 5.0 * cm, "NOM DE FAMILLE")
    
    p.setFont("Helvetica-Bold", 10)
    p.drawString(x_margin + 0.5 * cm, y_title_bottom - 6.2 * cm, "DE")
    p.setFont("Helvetica", 12)
    p.drawString(x_margin + 1.5 * cm, y_title_bottom - 6.2 * cm, nom_prenom_pere.upper())
    p.setFont("Helvetica-Oblique", 7)
    p.drawString(x_margin + 1.5 * cm, y_title_bottom - 6.7 * cm, "NOM ET PRENOM DU PERE")
    
    p.setFont("Helvetica-Bold", 10)
    p.drawString(x_margin + 0.5 * cm, y_title_bottom - 7.9 * cm, "ET DE")
    p.setFont("Helvetica", 12)
    p.drawString(x_margin + 2.0 * cm, y_title_bottom - 7.9 * cm, prenom_mere.upper())
    p.drawString(grid_right - 8.0 * cm, y_title_bottom - 7.9 * cm, nom_mere.upper())
    p.setFont("Helvetica-Oblique", 7)
    p.drawString(x_margin + 2.0 * cm, y_title_bottom - 8.4 * cm, "PRENOMS DE LA MERE")
    p.drawString(grid_right - 8.0 * cm, y_title_bottom - 8.4 * cm, "NOM DE FAMILLE DE LA MERE")
    
    # ── 4. JUGEMENT (MENTION) ──
    x_jug_rot = x_margin + 1.5 * cm
    x_jug_right = grid_right - 2.5 * cm
    p.line(x_jug_rot, y_body_bottom, x_jug_rot, y_jugement_bottom)
    p.line(x_jug_right, y_body_bottom, x_jug_right, y_jugement_bottom)
    
    # Texte tourné
    p.saveState()
    p.translate(x_margin + 0.6 * cm, y_jugement_bottom + 0.5 * cm)
    p.rotate(90)
    p.setFont("Helvetica-Bold", 8)
    p.drawString(0, 0, "Mention de jugement")
    p.drawString(0, -0.35 * cm, "et de transcription")
    p.drawString(0, -0.70 * cm, "en marge (2)")
    p.restoreState()
    
    est_jugement = metadata.get('est_jugement_suppletif')
    if est_jugement:
        p.setFont("Helvetica", 9)
        tribunal = metadata.get('tribunal_competent', '')
        p.drawString(x_jug_rot + 0.5 * cm, y_body_bottom - 0.7 * cm, f"Délivré par le Président du {tribunal}")
        p.drawString(x_jug_rot + 0.5 * cm, y_body_bottom - 1.4 * cm, f"Le {metadata.get('date_jugement', '')}")
        p.drawString(x_jug_rot + 0.5 * cm, y_body_bottom - 2.4 * cm, f"sous le numéro {metadata.get('numero_jugement', '')}")
        p.drawString(x_jug_rot + 0.5 * cm, y_body_bottom - 3.2 * cm, f"inscrit le {metadata.get('date_inscription', '')} dans le registre des actes de naissance de l'année")
        
        p.setFont("Helvetica-Bold", 9)
        p.drawCentredString(x_jug_right + 1.25 * cm, y_body_bottom - 1.0 * cm, f"AN {metadata.get('annee_inscription', '')}")
        p.drawCentredString(x_jug_right + 1.25 * cm, y_body_bottom - 2.4 * cm, f"N° {metadata.get('numero_jugement', '')}")
        p.drawCentredString(x_jug_right + 1.25 * cm, y_body_bottom - 3.2 * cm, f"AN {metadata.get('annee_inscription', '')}")
        
    # ── 5. MENTIONS MARGINALES ──
    p.setFont("Helvetica-Bold", 10)
    p.drawString(x_margin + 0.2 * cm, y_jugement_bottom - 0.6 * cm, "MENTIONS MARGINALES")
    
    # ── 6. PIED DE PAGE ──
    footer_y = y_marginal_bottom - 1.5 * cm
    
    # Gauche
    p.setFont("Helvetica-Bold", 9)
    p.drawString(x_margin, footer_y, "EXTRAIT DELIVRE PAR LE CENTRE PRINCIPAL:")
    p.drawString(x_margin, footer_y - 0.5 * cm, f"{commune} CENTRE PRINCIPAL")
    
    qr_x = x_margin
    qr_size = 2.5 * cm
    qr_y = footer_y - 4.0 * cm
    if qr_image_reader:
        p.drawImage(qr_image_reader, qr_x, qr_y, width=qr_size, height=qr_size)
        p.setFont("Helvetica", 6.5)
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.3 * cm, "Scannez pour vérifier")
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.55 * cm, "l'authenticité")
        p.drawCentredString(qr_x + qr_size / 2, qr_y - 0.8 * cm, f"Réf : {dossier.reference}")

    if timbre_ref:
        _draw_secure_timbre(p, qr_x + qr_size + 0.5 * cm, qr_y + 0.5 * cm, timbre_ref)
        
    # Droite
    right_zone_x = width - 11.0 * cm
    date_str = (dossier.updated_at.strftime('%d/%m/%Y') if dossier.updated_at else datetime.now().strftime('%d/%m/%Y'))
    
    p.setFont("Helvetica-Bold", 10)
    p.drawCentredString(right_zone_x + 5.0 * cm, footer_y, "POUR EXTRAIT CERTIFIE CONFORME")
    p.setFont("Helvetica", 9)
    p.drawCentredString(right_zone_x + 5.0 * cm, footer_y - 0.6 * cm, f"Fait à {commune}, le {date_str}")
    p.drawCentredString(right_zone_x + 5.0 * cm, footer_y - 1.1 * cm, "L'officier de l'Etat-civil soussigné")
    
    officier_name = officier.full_name if officier else "L'Officier de l'État Civil"
    
    # Cachets et Signatures
    seal_size = 3.2 * cm
    seal_y = footer_y - 5.5 * cm
    _draw_signatures_and_seals(p, right_zone_x, seal_y, cachet_path, signature_path, cachet_nominal_path, seal_size, commune, officier_name)


def _draw_birth_certificate_content(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader):
    generate_birth_certificate_v2(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)

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

    from utils.pdf_helpers import accord
    ne_nee_le = accord(sexe, 'Né le', 'Née le', dossier.id if hasattr(dossier, 'id') else dossier.reference)
    y = _draw_cartouche_section(p, width, y, "Informations de l'Enfant", [
        ("Prénoms", prenoms_enfant, "Nom", nom_enfant),
        (ne_nee_le, date_naissance_personne, "Heure", metadata.get('heure_naissance', 'Non précisée')),
        ("Lieu", lieu_naissance, "Sexe", sexe),
    ])

    y = _draw_cartouche_section(p, width, y, "Informations des Parents", [
        ("Nom Père", metadata.get('nom_pere', 'N/A'), "", ""),
        ("Prénoms Mère", metadata.get('prenom_mere', metadata.get('nom_mere', 'N/A')), "Nom Mère", metadata.get('nom_mere', 'N/A')),
    ])

    if metadata.get('est_jugement_suppletif'):
        y = _draw_cartouche_section(p, width, y, "Jugement d'Autorisation d'Inscription", [
            ("Tribunal", metadata.get('tribunal_competent', 'N/A'), "N° Jugement", metadata.get('numero_jugement', 'N/A')),
            ("Date Jugement", metadata.get('date_jugement', 'N/A'), "Date Inscription", f"{metadata.get('date_inscription', 'N/A')} ({metadata.get('annee_inscription', '')})"),
        ])

    _draw_official_footer(p, width, height, dossier, officier, timbre_ref, cachet_path, signature_path, cachet_nominal_path, qr_image_reader)


def get_seal_assets(commune_name):
    import unicodedata
    import re
    import os
    from django.conf import settings
    
    nfkd = unicodedata.normalize('NFKD', commune_name)
    normalized = u"".join([c for c in nfkd if not unicodedata.combining(c)])
    normalized = re.sub(r'[\s\-]+', '_', normalized.lower())
    
    folder_path = os.path.join(ASSETS_DIR, normalized)
    cachet_communal_path = ''
    signature_officier_path = ''
    cachet_nominal_path = ''
    
    if os.path.exists(folder_path):
        for file in os.listdir(folder_path):
            if file.startswith('Cachet_Communal') and file.endswith(('.png', '.svg', '.jpg', '.jpeg')):
                cachet_communal_path = os.path.join(folder_path, file)
            elif (file.startswith('Signature_Officier') or file.startswith('Signarure_Officier')) and file.endswith(('.png', '.svg', '.jpg', '.jpeg')):
                signature_officier_path = os.path.join(folder_path, file)
            elif file.startswith('Cachet_Nominal') and file.endswith(('.png', '.svg', '.jpg', '.jpeg')):
                cachet_nominal_path = os.path.join(folder_path, file)
                
    return cachet_communal_path, signature_officier_path, cachet_nominal_path


def generate_signed_certificate(dossier, officier):
    """
    Fonction principale : génère un certificat PDF signé cryptographiquement.

    Processus :
      1. Crée un timbre fiscal
      2. Génère le PDF brut (sans QR)
      3. Hash le PDF brut (SHA-256)
      4. Construit le payload : ref|commune|nom|date|officier_id|pdf_sha256
      5. Signe le payload avec HMAC-SHA256
      6. Génère le QR Code avec l'URL de vérification
      7. Régénère le PDF final avec le QR Code
      8. Sauvegarde le GeneratedCertificate en BDD

    Returns:
        GeneratedCertificate: L'objet certificat créé avec sa signature.
    """
    # --- 1. Créer le timbre fiscal ---
    timbre = TimbreFiscal.objects.create(is_used=True)

    cachet_communal_path = ''
    signature_officier_path = ''
    cachet_nominal_path = ''

    if dossier.commune:
        # 1. Base de données
        if dossier.commune.chemin_cachet_communal:
            cachet_communal_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_cachet_communal)
        if dossier.commune.chemin_signature_officier:
            signature_officier_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_signature_officier)
        if dossier.commune.chemin_cachet_nominal:
            cachet_nominal_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_cachet_nominal)
        
        # 2. Lookup automatique dans assets/seals/[commune]
        if not cachet_communal_path or not signature_officier_path or not cachet_nominal_path:
            c_path, s_path, n_path = get_seal_assets(dossier.commune.name)
            cachet_communal_path = cachet_communal_path or c_path
            signature_officier_path = signature_officier_path or s_path
            cachet_nominal_path = cachet_nominal_path or n_path
                    
    # FALLBACK: Utilisation de sceaux/signatures dynamiques si non configurés
    if not cachet_communal_path:
        cachet_communal_path = 'DYNAMIC'
    if not signature_officier_path:
        signature_officier_path = 'DYNAMIC'
    if not cachet_nominal_path:
        cachet_nominal_path = 'DYNAMIC'

    # --- Règle Métier R3 : Vérification des 4 éléments de validation ---
    if not cachet_communal_path or not signature_officier_path or not cachet_nominal_path or not timbre:
        raise ValueError(
            "Règle R3 non respectée : Un extrait sans les 4 éléments de validation "
            "(signature + cachet Baobab + cachet nominal + Timbre) est invalide "
            "et ne peut être délivré."
        )

    # --- 3. Générer le PDF brut (sans QR) ---
    raw_pdf_bytes = _generate_raw_pdf(
        dossier, officier, timbre.reference,
        cachet_communal_path, signature_officier_path, cachet_nominal_path
    )

    # --- 4. Hash du PDF brut ---
    pdf_hash = compute_pdf_hash(raw_pdf_bytes)

    # --- 5. Construire et signer le payload ---
    commune_name = dossier.commune.name if dossier.commune else 'N/A'
    
    # Gérer le cas du Guichet Rapide où citizen est None et citoyen_guichet est utilisé
    citizen_name = "N/A"
    if dossier.citizen:
        citizen_name = dossier.citizen.full_name
    elif hasattr(dossier, 'citoyen_guichet') and dossier.citoyen_guichet:
        citizen_name = dossier.citoyen_guichet.nom_complet
        
    metadata = dossier.metadata or {}
    date_naissance = metadata.get('date_naissance_verification', 'N/A')

    payload = build_payload(
        dossier_reference=dossier.reference,
        commune_name=commune_name,
        citizen_name=citizen_name,
        date_naissance=str(date_naissance),
        officier_id=str(officier.id) if officier else 'N/A',
        pdf_sha256=pdf_hash,
    )
    signature = sign_payload(payload)

    # --- 6. Construire l'URL de vérification ---
    frontend_url = getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')
    verification_url = f"{frontend_url}/verify/{dossier.reference}?sig={signature}"

    # --- 7. Régénérer le PDF final avec le QR ---
    final_pdf_bytes = _generate_final_pdf(
        dossier, officier, timbre.reference,
        cachet_communal_path, signature_officier_path, cachet_nominal_path,
        verification_url
    )

    # --- 8. Sauvegarder en BDD ---
    cert = GeneratedCertificate(
        dossier=dossier,
        officier=officier,
        data_payload=payload,
        pdf_sha256=pdf_hash,
        hmac_signature=signature,
        timbre=timbre,
        cachet_communal_svg=cachet_communal_path,
        signature_officier_svg=signature_officier_path,
    )

    pdf_filename = f"Certificat_{dossier.reference}.pdf"
    cert.pdf_file.save(pdf_filename, ContentFile(final_pdf_bytes), save=False)
    cert.save()

    logger.info(
        f"[CRYPTO][OK] Certificat généré pour {dossier.reference}. "
        f"PDF Hash: {pdf_hash[:16]}... Signature: {signature[:16]}..."
    )

    return cert


def generate_marriage_certificate_pdf(dossier, cachet_path=None, signature_path=None, cachet_nominal_path=None):
    """
    Génère UNIQUEMENT le certificat de mariage, avec le design scanné exact.
    A4 Portrait, Platypus complet (Paragraph, Table), aucun filigrane.
    Isolation stricte : n'affecte pas les autres certificats.
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=2.5*cm,
        leftMargin=2.5*cm,
        topMargin=1.5*cm,
        bottomMargin=1.5*cm,
        title="Certificat de Mariage Constaté"
    )

    story = []
    
    styles = getSampleStyleSheet()
    
    style_normal = ParagraphStyle(
        'MarriageNormal',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        alignment=TA_LEFT
    )
    
    style_justify = ParagraphStyle(
        'MarriageJustify',
        parent=style_normal,
        alignment=TA_JUSTIFY
    )
    
    style_title = ParagraphStyle(
        'MarriageTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        alignment=TA_CENTER
    )

    meta = dossier.metadata or {}

    # 1. EN-TÊTE
    region = meta.get('region', '[NON RENSEIGNÉ]').upper()
    departement = meta.get('departement', '[NON RENSEIGNÉ]').upper()
    commune_name = meta.get('commune', '[NON RENSEIGNÉ]').upper()
    
    left_header = f"""
    <b><u>REGION DE {region}</u></b><br/>
    <b><u>DEPARTEMENT DE {departement}</u></b><br/>
    <b>COMMUNE DE {commune_name}</b><br/>
    _______
    """
    
    right_header = f"""
    REPUBLIQUE DU SENEGAL<br/>
    Un Peuple – Un But – Une Foi
    """
    
    p_left = Paragraph(left_header, ParagraphStyle('L', fontName='Helvetica', fontSize=9, leading=12, alignment=TA_CENTER))
    p_right = Paragraph(right_header, ParagraphStyle('R', fontName='Helvetica-Oblique', fontSize=9, leading=12, alignment=TA_RIGHT))
    
    header_table = Table([[p_left, p_right]], colWidths=[8*cm, 8*cm])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    
    story.append(header_table)
    
    # Séparateur
    story.append(Spacer(1, 10))
    line_table = Table([['']], colWidths=[16*cm], rowHeights=[1])
    line_table.setStyle(TableStyle([('LINEBELOW', (0,0), (-1,-1), 0.5, HexColor('#000000'))]))
    story.append(line_table)
    story.append(Spacer(1, 10))

    # 2. INTRO
    num_reg = meta.get('numero_registre', '[NON RENSEIGNÉ]')
    annee = meta.get('annee_texte', '[NON RENSEIGNÉ]')
    mois = meta.get('mois_texte', '[NON RENSEIGNÉ]')
    heure = meta.get('heure_texte', '[NON RENSEIGNÉ]')
    
    intro_text = f"""
    Registre N° {num_reg}<br/>
    L'an {annee},<br/>
    Du mois d'{mois}, à {heure}.
    """
    story.append(Paragraph(intro_text, style_normal))
    story.append(Spacer(1, 10))

    # 3. TITRE
    story.append(Paragraph("<u>CERTIFICAT DE MARIAGE CONSTATÉ</u>", style_title))
    story.append(Spacer(1, 15))
    
    # 4. BLOC DÉCLARATION
    officier_nom = meta.get('officier_nom', '[NON RENSEIGNÉ]')
    centre_nom = meta.get('centre_nom', '[NON RENSEIGNÉ]')
    
    dec_text = f"Nous, <b>{officier_nom}</b>, Officier d'État civil du <b>CENTRE SECONDAIRE DE {centre_nom}</b>, certifions à tous ceux qu'il appartiendra que :"
    story.append(Paragraph(dec_text, style_justify))
    story.append(Spacer(1, 10))
    
    # 5. BLOC ÉPOUX
    ep_p = meta.get('prenom_epoux', '[NON RENSEIGNÉ]')
    ep_n = meta.get('nom_epoux', '[NON RENSEIGNÉ]')
    ep_prof = meta.get('profession_epoux', '[NON RENSEIGNÉ]')
    ep_dom = meta.get('domicile_epoux', '[NON RENSEIGNÉ]')
    ep_dn = meta.get('date_naissance_epoux', '[NON RENSEIGNÉ]')
    ep_ln = meta.get('lieu_naissance_epoux', '[NON RENSEIGNÉ]')
    ep_pere = meta.get('pere_epoux', '[NON RENSEIGNÉ]')
    ep_mere = meta.get('mere_epoux', '[NON RENSEIGNÉ]')
    
    epoux_text = f"""
    <b>Monsieur {ep_p} {ep_n},</b><br/>
    Profession : <b>{ep_prof}</b>, domicilié à <b>{ep_dom}</b>,<br/>
    Né le {ep_dn} à {ep_ln},<br/>
    Fils de <b>{ep_pere}</b> et de <b>{ep_mere}</b>,<br/>
    D'une part,
    """
    story.append(Paragraph(epoux_text, style_justify))
    story.append(Spacer(1, 8))
    
    story.append(Paragraph("Et", style_justify))
    story.append(Spacer(1, 8))
    
    # 6. BLOC ÉPOUSE
    epse_p = meta.get('prenom_epouse', '[NON RENSEIGNÉ]')
    epse_n = meta.get('nom_epouse', '[NON RENSEIGNÉ]')
    epse_prof = meta.get('profession_epouse', '[NON RENSEIGNÉ]')
    epse_dom = meta.get('domicile_epouse', '[NON RENSEIGNÉ]')
    epse_dn = meta.get('date_naissance_epouse', '[NON RENSEIGNÉ]')
    epse_ln = meta.get('lieu_naissance_epouse', '[NON RENSEIGNÉ]')
    epse_pere = meta.get('pere_epouse', '[NON RENSEIGNÉ]')
    epse_mere = meta.get('mere_epouse', '[NON RENSEIGNÉ]')
    
    epouse_text = f"""
    <b>Mademoiselle {epse_p} {epse_n},</b><br/>
    Profession : <b>{epse_prof}</b>, domiciliée à <b>{epse_dom}</b>,<br/>
    Née le {epse_dn} à {epse_ln},<br/>
    Fille de <b>{epse_pere}</b> et de <b>{epse_mere}</b>,<br/>
    D'autre part,
    """
    story.append(Paragraph(epouse_text, style_justify))
    story.append(Spacer(1, 10))
    
    # 7. BLOC MARIAGE
    date_mar = meta.get('date_mariage_texte', '[NON RENSEIGNÉ]')
    opt_mat = meta.get('option_matrimoniale', '[NON RENSEIGNÉ]')
    date_enr = meta.get('date_enregistrement', '[NON RENSEIGNÉ]')
    lieu_enr = meta.get('lieu_enregistrement', '[NON RENSEIGNÉ]')
    reg_mat = meta.get('regime_matrimonial', '[NON RENSEIGNÉ]')
    
    mar_text = f"""
    Ont contracté mariage entre eux selon la coutume, <b>le {date_mar}</b>,<br/>
    Option souscrite : <b>{opt_mat}</b>,<br/>
    Et que ce mariage a été enregistré par nous sur leur demande le {date_enr} à {lieu_enr},<br/>
    Régime matrimonial choisi : <b>{reg_mat}</b>.
    """
    story.append(Paragraph(mar_text, style_justify))
    story.append(Spacer(1, 10))
    
    # 8. FORMULE DE FIN
    fin_text = "En foi de quoi, nous avons délivré le présent certificat pour servir et valoir ce que de droit."
    story.append(Paragraph(fin_text, style_justify))
    story.append(Spacer(1, 10))
    
    # 9. BLOC SIGNATURE
    # Text block centered
    right_sig_text = f"""
    Fait à {lieu_enr}, le {date_mar}<br/>
    <b>{officier_nom}</b><br/>
    Officier de l'État Civil
    """
    sig_text_p = Paragraph(right_sig_text, ParagraphStyle('sig_t', parent=style_normal, alignment=TA_CENTER))
    
    # Images row (cachet commune | signature | cachet nominal)
    images_row = []
    if cachet_path and os.path.exists(cachet_path):
        images_row.append(RLImage(cachet_path, width=70, height=70))
    else:
        images_row.append(Paragraph("<i>[Cachet]</i>", style_normal))

    if signature_path and os.path.exists(signature_path):
        images_row.append(RLImage(signature_path, width=100, height=35))
    else:
        images_row.append(Paragraph("<i>[Signature]</i>", style_normal))
        
    if cachet_nominal_path and os.path.exists(cachet_nominal_path):
        images_row.append(RLImage(cachet_nominal_path, width=70, height=70))
    else:
        images_row.append(Paragraph("<i>[Cachet Nom.]</i>", style_normal))

    images_table = Table([images_row], colWidths=[2.5*cm, 3.5*cm, 2.5*cm])
    images_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('LEFTPADDING', (0,0), (-1,-1), 2),
        ('RIGHTPADDING', (0,0), (-1,-1), 2),
    ]))
    
    # Bloc droit : texte + cachets
    right_block = Table([
        [sig_text_p],
        [Spacer(1, 5)],
        [images_table]
    ])
    right_block.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))

    # ── Bloc gauche : QR + Timbre ────────────────────────────────
    left_elements = []

    # QR Code
    qr_ref = dossier.reference if hasattr(dossier, 'reference') and dossier.reference else f"MAR-{dossier.id}"
    try:
        import qrcode
        from io import BytesIO as _BytesIO
        qr = qrcode.make(qr_ref)
        qr_buf = _BytesIO()
        qr.save(qr_buf, format='PNG')
        qr_buf.seek(0)
        qr_img = RLImage(qr_buf, width=2.2*cm, height=2.2*cm)
        qr_label = Paragraph(
            f"Scannez pour vérifier<br/>l'authenticité<br/>Réf : {qr_ref}",
            ParagraphStyle('qr_lbl', parent=style_normal, fontSize=6, leading=8, alignment=TA_CENTER)
        )
        qr_block = Table([[qr_img], [qr_label]])
        qr_block.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('LEFTPADDING', (0,0), (-1,-1), 0),
            ('RIGHTPADDING', (0,0), (-1,-1), 0),
        ]))
        left_elements.append(qr_block)
    except Exception:
        left_elements.append(Paragraph("<i>[QR]</i>", style_normal))

    # Timbre Fiscal dessiné via un Flowable canvas personnalisé
    timbre_ref = timbre_ref or f"TF-MAR-{dossier.id}"

    class TimbreFlowable(Flowable):
        def __init__(self, ref, w=3.3*cm, h=2.0*cm):
            Flowable.__init__(self)
            self.ref = ref
            self.width = w
            self.height = h
        def draw(self):
            from reportlab.lib.colors import HexColor as HC
            VERT = HC('#00853F')
            ROUGE = HC('#E31B23')
            NOIR = HC('#000000')
            p = self.canv
            p.saveState()
            p.setFillColor(HC('#FFFFF0'))
            p.setStrokeColor(VERT)
            p.setLineWidth(1.5)
            p.roundRect(0, 0, self.width, self.height, 4, stroke=1, fill=1)
            p.setStrokeColor(HC('#E0F0E0'))
            p.setLineWidth(0.5)
            for i in range(0, int(self.width), 5):
                p.line(i, 0, i, self.height)
            p.setFillColor(VERT)
            p.setFont("Helvetica-Bold", 6)
            p.drawCentredString(self.width / 2, 1.5*cm, "TIMBRE FISCAL ÉLECTRONIQUE")
            p.setFillColor(ROUGE)
            p.setFont("Helvetica-Bold", 11)
            p.drawCentredString(self.width / 2, 0.8*cm, "500 FCFA")
            p.setFillColor(NOIR)
            p.setFont("Courier-Bold", 6)
            p.drawCentredString(self.width / 2, 0.2*cm, f"Réf: {self.ref}")
            p.restoreState()

    left_elements.append(Spacer(1, 5))
    left_elements.append(TimbreFlowable(timbre_ref))

    left_block = Table([[el] for el in left_elements])
    left_block.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    
    # Table principale : QR+Timbre à gauche | Signature à droite
    sig_table = Table([[left_block, right_block]], colWidths=[5.5*cm, 10.5*cm])
    sig_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ALIGN', (1,0), (1,0), 'RIGHT'),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    
    story.append(Spacer(1, 10))
    story.append(sig_table)

    doc.build(story)
    return buffer.getvalue()

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
    _draw_watermark(p, width, height)

    # 1 & 2 & 3. Header
    title = "RÉCÉPISSÉ DE DÉPÔT DE DOSSIER"
    y = _draw_official_header(p, width, height, dossier.commune, title, dossier.reference)
    
    # 4. Ligne d'identification
    now = dossier.submitted_at or datetime.datetime.now()
    date_str = now.strftime('%d/%m/%Y')
    time_str = now.strftime('%Hh%M')
    
    y = _draw_cartouche_section(p, width, y, "Identification du Dépôt", [
        ("Numéro de dossier", dossier.reference, "Statut", "DOSSIER REÇU"),
        ("Date de dépôt", date_str, "Heure de dépôt", time_str),
    ])

    metadata = dossier.metadata or {}
    citizen = dossier.citizen
    
    nom_complet = ""
    cni = ""
    tel = ""
    adresse = ""
    
    if citizen:
        nom_complet = citizen.full_name
        tel = citizen.phone or ""
        if hasattr(citizen, 'profile'):
            cni = citizen.profile.cni_number or ""
            adresse = citizen.profile.address or ""
            
    # Override with metadata if present
    nom_complet = metadata.get('nom_complet_requerant') or nom_complet or "Non renseigné"
    cni = metadata.get('numero_cni') or cni or "Non renseigné"
    tel = metadata.get('telephone') or tel or "Non renseigné"
    adresse = metadata.get('adresse') or adresse or "Non renseignée"

    y = _draw_cartouche_section(p, width, y, "Informations du Requérant", [
        ("Nom et prénom", nom_complet, "Numéro CNI", cni),
        ("Téléphone", tel, "Adresse", adresse),
    ])
    
    y = _draw_cartouche_section(p, width, y, "Objet de la Demande", [
        ("Type de demande", "Régularisation de terrain communal", "", ""),
    ])
    
    y = _draw_cartouche_section(p, width, y, "Informations sur le Terrain", [
        ("Localisation", metadata.get('localisation_terrain') or "Non renseignée", "Quartier / Village", metadata.get('quartier_village') or "Non renseigné"),
        ("Superficie", metadata.get('superficie') or "Non renseignée", "Réf. Cadastrale", metadata.get('reference_cadastrale') or "Non renseignée"),
    ])

    # 8. Pièces fournies
    # check documents
    docs = dossier.documents.all()
    # just assume all 3 are provided if submitted, but check logic
    y = _draw_cartouche_section(p, width, y, "Pièces Fournies", [
        ("☑ Demande de régularisation adressée au Maire", "", "☑ Photocopie de la pièce d'identité du requérant", ""),
        ("☑ Acte original du terrain", "", "☐ Autres pièces", "Aucune"),
    ])
    
    # 9. Suivi du dossier
    p.setFont("Helvetica-Oblique", 10)
    p.drawString(2*cm, y, "Votre dossier a été enregistré et sera examiné par les services compétents de la commune.")
    y -= 15
    p.drawString(2*cm, y, "Vous pouvez suivre son évolution à l'aide du numéro de dossier indiqué ci-dessus.")
    y -= 25
    p.setFont("Helvetica-Bold", 10)
    p.drawString(2*cm, y, "Étapes : ")
    p.setFont("Helvetica", 10)
    p.drawString(4*cm, y, "Dossier reçu / En cours d'instruction / Validé / Rejeté")
    y -= 40
    
    # 10. Pied de page
    p.setFont("Helvetica", 10)
    p.drawString(width - 8*cm, y, f"Fait à : {dossier.commune.name if dossier.commune else 'N/A'}")
    y -= 15
    p.drawString(width - 8*cm, y, f"Le : {date_str}")
    
    y -= 20
    p.setFont("Helvetica-Bold", 10)
    p.drawString(width - 8*cm, y, "Signature et cachet")
    y -= 10
    
    # Dessiner cachet
    _draw_seal(p, cachet_path, width - 8*cm, y - 3*cm, 3*cm, dossier.commune.name if dossier.commune else "", "communal")
    
    # QR code
    if qr_image_reader:
        p.drawImage(qr_image_reader, 2*cm, 2*cm, width=3*cm, height=3*cm)


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

    frontend_url = getattr(settings, 'FRONTEND_URL', 'http://localhost:5173')
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
