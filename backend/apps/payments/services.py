import io
import os
from django.conf import settings
from reportlab.lib.pagesizes import A5
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle

def generate_receipt_pdf(transaction):
    """
    Génère un reçu de paiement PDF format A5 avec ReportLab.
    """
    buffer = io.BytesIO()
    
    # A5 dimensions: 148mm de large x 210mm de haut
    p = canvas.Canvas(buffer, pagesize=A5)
    width, height = A5
    
    # Palette de couleurs
    PRIMARY = HexColor('#1D4ED8') # Bleu Premium
    SECONDARY = HexColor('#0F172A') # Ardoise Sombre
    LIGHT_BG = HexColor('#F8FAFC') # Gris très clair
    BORDER_COLOR = HexColor('#E2E8F0')
    GREEN_COLOR = HexColor('#10B981')
    
    # --- Fond et Bordure ---
    p.setFillColor(LIGHT_BG)
    p.rect(0, 0, width, height, fill=True, stroke=False)
    
    # Bordure principale
    p.setStrokeColor(BORDER_COLOR)
    p.setLineWidth(1)
    p.roundRect(8 * mm, 8 * mm, width - 16 * mm, height - 16 * mm, 4, fill=False, stroke=True)
    
    # --- En-tête ---
    # En-tête République du Sénégal (Simulation)
    p.setFillColor(SECONDARY)
    p.setFont("Helvetica-Bold", 8)
    p.drawCentredString(width / 2, height - 18 * mm, "RÉPUBLIQUE DU SÉNÉGAL")
    
    p.setFont("Helvetica", 7)
    # Récupérer la commune du dossier associé si possible, sinon commune par défaut
    commune_name = "COMMUNE DE TERANGA"
    if transaction.dossier and transaction.dossier.commune:
        commune_name = f"COMMUNE DE {transaction.dossier.commune.name.upper()}"
    p.drawCentredString(width / 2, height - 22 * mm, commune_name)
    p.drawCentredString(width / 2, height - 25 * mm, "SERVICE DE L'ÉTAT CIVIL")
    
    # Ligne de séparation sous en-tête
    p.setStrokeColor(HexColor('#CBD5E1'))
    p.setLineWidth(0.5)
    p.line(20 * mm, height - 28 * mm, width - 20 * mm, height - 28 * mm)
    
    # --- Titre du document ---
    p.setFillColor(PRIMARY)
    p.setFont("Helvetica-Bold", 14)
    p.drawCentredString(width / 2, height - 38 * mm, "REÇU DE PAIEMENT")
    
    # Numéro de reçu
    p.setFillColor(SECONDARY)
    p.setFont("Helvetica-Bold", 9)
    p.drawCentredString(width / 2, height - 44 * mm, f"N°: {transaction.receipt_number or 'N/A'}")
    
    # --- Boîte des détails du paiement ---
    box_x = 12 * mm
    box_y = 62 * mm
    box_w = width - 24 * mm
    box_h = 92 * mm
    
    p.setFillColor(HexColor('#FFFFFF'))
    p.setStrokeColor(BORDER_COLOR)
    p.roundRect(box_x, box_y, box_w, box_h, 6, fill=True, stroke=True)
    
    # Libellés et valeurs
    details = [
        ("Référence demande :", transaction.dossier.reference if transaction.dossier else "Guichet Rapide"),
        ("Service :", transaction.service_label),
        ("Citoyen :", transaction.payer_name),
        ("Téléphone/Identifiant :", transaction.payer_id),
        ("Date & Heure :", transaction.created_at.strftime('%d/%m/%Y %H:%M') if transaction.created_at else "Aujourd'hui"),
        ("Mode de paiement :", transaction.get_payment_type_display()),
    ]
    
    # Si paiement mobile, afficher la référence externe
    if transaction.transaction_reference:
        details.append(("Réf. Transaction :", transaction.transaction_reference))
    
    if transaction.comment:
        details.append(("Note :", transaction.comment))
        
    start_y = height - 60 * mm
    line_spacing = 7 * mm
    
    p.setFont("Helvetica", 9)
    for label, val in details:
        p.setFillColor(HexColor('#64748B')) # Slate-500
        p.drawString(16 * mm, start_y, label)
        p.setFillColor(SECONDARY)
        p.setFont("Helvetica-Bold", 9)
        p.drawString(55 * mm, start_y, str(val))
        p.setFont("Helvetica", 9)
        start_y -= line_spacing
        
    # Séparateur dans la boîte
    p.setStrokeColor(BORDER_COLOR)
    p.line(16 * mm, start_y + 2 * mm, width - 16 * mm, start_y + 2 * mm)
    
    # Section Montant
    start_y -= 2 * mm
    p.setFillColor(SECONDARY)
    p.setFont("Helvetica-Bold", 10)
    p.drawString(16 * mm, start_y, "MONTANT PAYÉ :")
    
    p.setFillColor(PRIMARY)
    p.setFont("Helvetica-Bold", 12)
    amount_str = f"{float(transaction.amount):,.0f} XOF".replace(',', ' ')
    p.drawRightString(width - 16 * mm, start_y, amount_str)
    
    # --- Pied de page / Validation ---
    p.setFillColor(SECONDARY)
    p.setFont("Helvetica-Bold", 8)
    agent_name = transaction.agent.full_name if transaction.agent else "Système"
    p.drawString(16 * mm, 45 * mm, "Agent de caisse :")
    p.setFont("Helvetica", 8)
    p.drawString(42 * mm, 45 * mm, agent_name)
    
    # Badge statut "PAYÉ"
    p.saveState()
    p.setFillColor(HexColor('#DCFCE7')) # Vert clair
    p.setStrokeColor(GREEN_COLOR)
    p.setLineWidth(1)
    p.roundRect(width - 45 * mm, 38 * mm, 30 * mm, 10 * mm, 3, fill=True, stroke=True)
    p.setFillColor(HexColor('#065F46')) # Vert foncé
    p.setFont("Helvetica-Bold", 10)
    p.drawCentredString(width - 30 * mm, 41.5 * mm, "PAYÉ")
    p.restoreState()
    
    # Mentions légales bas de page
    p.setFillColor(HexColor('#94A3B8'))
    p.setFont("Helvetica-Oblique", 7)
    p.drawCentredString(width / 2, 18 * mm, "Ce reçu numérique tient lieu de preuve de paiement.")
    p.drawCentredString(width / 2, 14 * mm, "Teranga Civil — Gestion de l'état civil")
    
    p.showPage()
    p.save()
    
    buffer.seek(0)
    return buffer.getvalue()
