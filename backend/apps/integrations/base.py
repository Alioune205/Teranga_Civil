"""
Intégrations mocks — Base abstraite pour tous les clients d'intégration.

Architecture :
    - Chaque service externe (ANEC, Paiement) hérite de `BaseMockClient`
    - Interface standardisée : ping(), log_call(), health_status()
    - En production, swap transparent vers les vrais SDK/API
"""
import time
import logging
from abc import ABC, abstractmethod

logger = logging.getLogger('system')


class BaseMockClient(ABC):
    """
    Classe de base pour toutes les intégrations (mocks et production).

    Garantit :
        - Une interface standardisée pour les appels externes
        - Un logging structuré de chaque appel
        - Un health check utilisable par le monitoring
    """

    def __init__(self, service_name):
        self.service_name = service_name
        self.logger = logger

    def log_call(self, endpoint, payload):
        """Log structuré de chaque appel externe."""
        self.logger.info(
            f'[{self.service_name}] Appel → {endpoint} | Payload: {payload}'
        )

    @abstractmethod
    def ping(self):
        """Vérifie si le service externe est disponible."""
        pass

    def health_status(self):
        """
        Retourne le statut de santé du service avec mesure de latence.
        Utilisé par le health check global du système.
        """
        try:
            start = time.monotonic()
            result = self.ping()
            latency_ms = round((time.monotonic() - start) * 1000, 2)
            return {
                'service': self.service_name,
                'status': 'up',
                'latency_ms': latency_ms,
                'details': result,
            }
        except Exception as e:
            self.logger.error(
                f'[{self.service_name}] Health check failed: {e}'
            )
            return {
                'service': self.service_name,
                'status': 'down',
                'error': str(e),
            }
