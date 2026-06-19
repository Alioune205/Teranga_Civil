import os
import re

from django.conf import settings
from django.core.management.base import BaseCommand
from langchain_community.vectorstores import Chroma
from langchain_huggingface import HuggingFaceEmbeddings


class Command(BaseCommand):
    help = "Ingère le fichier Procedures et documents.md dans ChromaDB"

    def handle(self, *args, **options):
        md_file_path = os.path.join(
            settings.BASE_DIR.parent, "Procedures et documents.md"
        )

        if not os.path.exists(md_file_path):
            self.stdout.write(self.style.ERROR(f"Fichier introuvable: {md_file_path}"))
            return

        with open(md_file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Split par les numéros de procédure "1. ACTE DE NAISSANCE"
        # Regex pour matcher un chiffre suivi d'un point au début d'une ligne
        pattern = re.compile(r"^(?=\d+\.\s+[A-Z])", re.MULTILINE)
        sectionsRaw = pattern.split(content)

        documents = []
        metadatas = []

        for section in sectionsRaw:
            section = section.strip()
            if not section:
                continue

            # Extraire le titre (la première ligne)
            lines = section.split("\n")
            title = lines[0].strip()

            documents.append(section)
            metadatas.append({"source": "Procedures et documents.md", "sujet": title})
            self.stdout.write(f"-> Préparation ingestion: {title}")

        try:
            persist_directory = os.path.join(settings.BASE_DIR, "chroma_db")
            embeddings = HuggingFaceEmbeddings(
                model_name="sentence-transformers/all-MiniLM-L6-v2"
            )
            vector_store = Chroma(
                collection_name="teranga_procedures",
                embedding_function=embeddings,
                persist_directory=persist_directory,
            )

            # Reset de la collection si on re-ingère
            # Pour Chroma récent: on peut utiliser client.delete_collection

            self.stdout.write("Ajout des textes à ChromaDB...")
            vector_store.add_texts(texts=documents, metadatas=metadatas)

            self.stdout.write(
                self.style.SUCCESS(
                    f"Ingestion réussie de {len(documents)} procédures dans ChromaDB !"
                )
            )
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Erreur d'ingestion : {e}"))
