import os
import sys
import django

# Configuration Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
django.setup()

from apps.ai.vector_store import ingest_procedures

# Données d'exemple pour le RAG (à remplacer par de vrais documents juridiques ou un PDF parsing)
PROCEDURES = [
    "Pour un acte de mariage, veuillez vous munir des copies des pièces d'identité des époux et des témoins, ainsi que du certificat de célébration à la mairie ou à la mosquée/église.",
    "Pour obtenir un acte de naissance, vous devez fournir un certificat médical d'accouchement et une pièce d'identité des deux parents.",
    "L'acte de décès nécessite le certificat médical de constatation du décès délivré par un médecin agréé et le livret de famille ou la pièce d'identité du défunt.",
    "Le délai de traitement habituel des dossiers est de 48 à 72 heures ouvrables pour une demande classique.",
    "Les démarches d'état civil de base sont généralement gratuites. Cependant, les copies d'extraits nécessitent un timbre fiscal numérique de 500 FCFA.",
    "L'attestation de résidence (ou certificat de domicile) nécessite une copie de la carte nationale d'identité et une facture Senelec ou SDE à votre nom."
]

def run():
    print("Ingestion des procédures dans ChromaDB...")
    ingest_procedures(PROCEDURES)
    print("✅ Ingestion réussie. Le RAG est prêt à être utilisé par Ndiogoye.")

if __name__ == "__main__":
    run()
