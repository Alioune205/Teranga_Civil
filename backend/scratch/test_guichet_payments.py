import os
import django
import sys

# Configure Django settings
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.dossiers.models import Dossier
from apps.payments.models import PaymentTransaction, PaymentStatus, PaymentType
from apps.payments.services import generate_receipt_pdf
from apps.users.models import User
from django.utils import timezone

def test_guichet_flow():
    print("Démarrage du test du flux de paiement au guichet...")
    
    # Récupérer ou créer un agent
    agent = User.objects.filter(role='agent').first()
    if not agent:
        agent = User.objects.filter(is_superuser=True).first()
    if not agent:
        print("Erreur: Aucun agent trouvé.")
        return
        
    print(f"Agent test : {agent.full_name} ({agent.role})")
    
    # Trouver un dossier
    dossier = Dossier.objects.first()
    if not dossier:
        print("Erreur: Aucun dossier trouvé dans la base.")
        return
        
    print(f"Dossier test : {dossier.reference} - Statut actuel: {dossier.status}")
    
    # Générer un numéro de reçu unique
    import random
    receipt_number = f"REC-TEST-{random.randint(1000, 9999)}"
    
    # 1. Créer une transaction
    tx = PaymentTransaction.objects.create(
        reference=f"TX_TEST_{random.randint(1000, 9999)}",
        amount=1000.00,
        currency='XOF',
        payment_type=PaymentType.WAVE,
        status=PaymentStatus.PAID,
        payer_name="Test Citoyen",
        payer_id="770000000",
        service_label=f"Frais de traitement: {dossier.get_type_display()}",
        dossier=dossier,
        agent=agent,
        receipt_number=receipt_number,
        transaction_reference="WAVE_REF_1234",
        comment="Test de paiement au guichet"
    )
    
    print(f"Transaction créée : {tx.reference} - Reçu : {tx.receipt_number}")
    
    # 2. Mettre à jour le dossier
    original_status = dossier.status
    dossier.status = Dossier.Status.SUBMITTED
    dossier.submitted_at = timezone.now()
    dossier.save()
    print(f"Statut du dossier mis à jour de {original_status} à {dossier.status}")
    
    # 3. Générer le reçu PDF
    print("Génération du reçu PDF...")
    pdf_bytes = generate_receipt_pdf(tx)
    
    # Sauvegarder dans un fichier local pour vérification
    output_filename = "test_recu_paiement.pdf"
    with open(output_filename, 'wb') as f:
        f.write(pdf_bytes)
        
    print(f"Reçu PDF sauvegardé avec succès dans : {os.path.abspath(output_filename)}")
    print("Test terminé avec succès !")

if __name__ == "__main__":
    test_guichet_flow()
