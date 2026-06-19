import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
django.setup()

from apps.ai.vector_store import ingest_procedures

# Base de connaissances juridique enrichie pour Ndiogoye (Etat Civil Sénégal)
PROCEDURES = [
    # Acte de naissance
    "Titre: Déclaration de Naissance. La déclaration de naissance est obligatoire et doit être faite dans un délai d'un an (12 mois) après l'accouchement. Passé ce délai, il faut recourir à un jugement d'autorisation d'inscription (jugement supplétif). Pièces requises : Le certificat d'accouchement délivré par la structure sanitaire, les pièces d'identité des parents, et éventuellement le livret de famille. Coût : La déclaration est gratuite. La délivrance de copies d'extraits coûte généralement 500 FCFA (timbre fiscal) par copie.",
    
    # Acte de mariage
    "Titre: Célébration et Déclaration de Mariage. Au Sénégal, on distingue le mariage célébré devant l'officier d'état civil et le mariage constaté (coutumier ou religieux). Pour un mariage célébré, les futurs époux doivent fournir : des extraits de naissance datant de moins de 3 mois, des copies de leurs pièces d'identité, celles de leurs témoins, et un certificat de non-grossesse pour la femme en cas de remariage. Pour un mariage constaté, l'attestation du célébrant (Imam, Prêtre) est indispensable. Le délai de déclaration d'un mariage constaté est de 6 mois.",
    
    # Acte de décès
    "Titre: Déclaration de Décès. La déclaration de décès doit être faite dans le délai d'un mois. Pièces à fournir : Certificat de genre de mort délivré par un médecin, la pièce d'identité du défunt (ou extrait de naissance), et la pièce d'identité du déclarant. Le certificat d'inhumation est souvent exigé. La démarche est gratuite.",
    
    # Certificat de résidence
    "Titre: Certificat de Résidence ou de Domicile. Ce document prouve qu'une personne réside effectivement dans la commune. Documents demandés : Une quittance SENELEC, SEN'EAU ou SONATEL récente (moins de 3 mois) au nom du demandeur, ou à défaut un certificat d'hébergement signé par le propriétaire, accompagné de la carte d'identité de l'hébergeur. Une copie de la CNI du demandeur est requise. Le timbre est généralement de 500 FCFA.",
    
    # Délais et tarifs
    "Titre: Délais de traitement et Tarification Générale. Les demandes faites via la plateforme TERANGA CIVIL (application mobile) ont un délai de traitement de 48h à 72h ouvrables pour les documents simples. Les frais de timbre fiscal pour les actes (naissance, mariage, décès) sont fixés à 500 FCFA. Les frais de livraison (si l'option est choisie) varient selon la zone (entre 1000 et 2000 FCFA).",
    
    # Jugement d'hérédité
    "Titre: Jugement d'hérédité (Certificat d'Hérédité). Nécessaire pour régler la succession d'un défunt. Cette démarche se fait au Tribunal d'Instance, pas à la Mairie. Il faut le certificat de décès, les actes de naissance de tous les héritiers, un certificat de mariage si le défunt était marié, et deux témoins. Ndiogoye ne gère pas ce document, le citoyen doit être orienté vers le tribunal."
]

def run():
    print("Ingestion de la base documentaire experte dans le RAG (ChromaDB)...")
    ingest_procedures(PROCEDURES)
    print("Base documentaire vectorisée avec succès ! Ndiogoye est maintenant un expert certifié.")

if __name__ == "__main__":
    run()
