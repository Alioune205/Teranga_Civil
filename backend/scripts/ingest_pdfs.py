import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
django.setup()

import pypdfium2 as pdfium
from apps.ai.vector_store import ingest_procedures

def chunk_text(text, chunk_size=500, overlap=100):
    """
    Découpe le texte en segments avec chevauchement.
    """
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

def extract_and_ingest_pdf(pdf_path):
    print(f"--- Lecture du fichier PDF : {os.path.basename(pdf_path)} ---")
    try:
        pdf = pdfium.PdfDocument(pdf_path)
        documents = []
        metadatas = []
        
        for page_index in range(len(pdf)):
            page = pdf[page_index]
            textpage = page.get_textpage()
            page_text = textpage.get_text_bounded()
            
            if not page_text.strip():
                continue
                
            print(f"Page {page_index + 1} : {len(page_text)} caractères extraits.")
            
            # Découper le texte de la page en morceaux
            page_chunks = chunk_text(page_text, chunk_size=600, overlap=120)
            
            for chunk_idx, chunk in enumerate(page_chunks):
                documents.append(chunk)
                metadatas.append({
                    "source": os.path.basename(pdf_path),
                    "page": page_index + 1,
                    "chunk_index": chunk_idx
                })
                
        pdf.close()
        
        if documents:
            print(f"Ingestion de {len(documents)} segments dans la base vectorielle...")
            ingest_procedures(documents, metadatas)
            print("Ingestion réussie !")
        else:
            print("Aucun texte trouvé à ingérer dans ce PDF.")
            
    except Exception as e:
        print(f"Erreur lors de la lecture ou l'ingestion du PDF: {e}")

def run_ingestion_folder(folder_path):
    if not os.path.exists(folder_path):
        print(f"Dossier introuvable : {folder_path}")
        return
        
    files = [f for f in os.listdir(folder_path) if f.endswith(".pdf")]
    if not files:
        print(f"Aucun fichier PDF trouvé dans {folder_path}")
        return
        
    print(f"Trouvé {len(files)} fichiers PDF à traiter.")
    for file in files:
        pdf_path = os.path.join(folder_path, file)
        extract_and_ingest_pdf(pdf_path)

if __name__ == "__main__":
    # Dossier par défaut : racine du projet ou backend
    default_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Lancement de l'extraction RAG sur le dossier : {default_dir}")
    
    # Ingestion de quelques fichiers officiels s'ils sont à la racine
    run_ingestion_folder(default_dir)
    
    # Ingestion également depuis le dossier parent si nécessaire
    parent_dir = os.path.dirname(default_dir)
    if default_dir != parent_dir:
        print(f"Vérification des PDF dans le dossier parent : {parent_dir}")
        run_ingestion_folder(parent_dir)
