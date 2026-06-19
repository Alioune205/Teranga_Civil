import logging
import os

from django.conf import settings
from langchain_community.vectorstores import Chroma
from langchain_huggingface import HuggingFaceEmbeddings

logger = logging.getLogger("apps")

# Mise en cache globale du modèle d'embeddings ET des bases vectorielles
try:
    _GLOBAL_EMBEDDINGS = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )
    _GLOBAL_VECTOR_STORE = Chroma(
        collection_name="teranga_procedures",
        embedding_function=_GLOBAL_EMBEDDINGS,
        persist_directory=os.path.join(settings.BASE_DIR, "chroma_db"),
    )
    _GLOBAL_CACHE_STORE = Chroma(
        collection_name="semantic_cache",
        embedding_function=_GLOBAL_EMBEDDINGS,
        persist_directory=os.path.join(settings.BASE_DIR, "chroma_cache"),
    )
except Exception as e:
    logger.error(f"Erreur chargement RAG global: {e}")
    _GLOBAL_EMBEDDINGS = None
    _GLOBAL_VECTOR_STORE = None
    _GLOBAL_CACHE_STORE = None

import json


class SemanticCache:
    """
    Gestion du cache sémantique pour économiser les requêtes Gemini.
    """

    def __init__(self):
        self.cache_store = _GLOBAL_CACHE_STORE

    def check_cache(self, query: str):
        if not self.cache_store:
            return None
        try:
            results = self.cache_store.similarity_search_with_score(query, k=1)
            if results:
                doc, distance = results[0]
                # Distance L2 : plus c'est proche de 0, plus c'est similaire (seuil à 0.15 = ~98% de similarité)
                if distance < 0.15:
                    logger.info("HIT CACHE SEMANTIQUE ! Economie d'un appel API.")
                    return json.loads(doc.page_content)
        except Exception as e:
            logger.error(f"Erreur Semantic Cache: {e}")
        return None

    def add_to_cache(self, query: str, response_dict: dict):
        if not self.cache_store:
            return
        try:
            if response_dict.get("action") == "RESPOND":
                self.cache_store.add_texts(
                    [json.dumps(response_dict)], metadatas=[{"query": query}]
                )
        except Exception as e:
            logger.error(f"Erreur ajout Semantic Cache: {e}")


class RetrieverService:
    """
    Couche 3: RAG (Retrieval) - Récupération d'information dans ChromaDB
    """

    def __init__(self):
        self.embeddings = _GLOBAL_EMBEDDINGS
        self.vector_store = _GLOBAL_VECTOR_STORE

    def retrieve_context(
        self, query: str, top_k: int = 5, threshold: float = 0.05
    ) -> str:
        """
        Récupère les documents les plus pertinents pour la requête.
        """
        if not self.vector_store:
            return ""

        try:
            results = self.vector_store.similarity_search_with_relevance_scores(
                query, k=top_k
            )

            valid_chunks = []
            for doc, score in results:
                logger.info(f"RAG Score: {score:.4f} | {doc.metadata.get('sujet', '')}")
                if score >= threshold:
                    valid_chunks.append(doc.page_content)

            return "\n\n".join(valid_chunks)
        except Exception as e:
            logger.error(f"Erreur lors de la récupération RAG: {e}")
            return ""
