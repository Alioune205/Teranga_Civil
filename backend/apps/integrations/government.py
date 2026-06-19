"""
Senegalese Government Portal Integration Service Stub.
"""
import logging
from .base import BaseIntegrationService

logger = logging.getLogger('apps.integrations.gov')


class GovernmentIntegrationStub(BaseIntegrationService):
    """
    Stub implementation for integrations with the unified government portal (Secrétariat Général du Gouvernement).
    Returns mock data for synchronization tasks and portal registries.
    """

    def authenticate(self):
        logger.info(f"Authentification au Portail Gouvernemental (URL: {self.api_url or 'https://api.gouv.sn'}) réussie.")
        return {"authenticated": True, "token": "stub-gov-session-token"}

    def fetch_citizen_data(self, cni_number):
        logger.info(f"Government Portal: Recherche du profil fiscal/social pour la CNI: {cni_number}")
        return {
            "success": True,
            "source": "Government Unified Registry",
            "data": {
                "cni_number": cni_number,
                "first_name": "Babacar",
                "last_name": "Diop",
                "address": "Villa 45, Sicap Liberté 4, Dakar",
                "phone": "+221775551234",
                "email": "babacar.diop@gouv.sn"
            }
        }

    def verify_civil_status_record(self, record_id, record_type):
        logger.info(f"Government Portal: Validation du certificat fiscal/adresse ID: {record_id}")
        return {
            "success": True,
            "record_id": record_id,
            "verified": True,
            "status": "valid",
            "issuer": "Direction Générale des Impôts et Domaines"
        }

    def transmit_dossier(self, dossier_data):
        logger.info(f"Government Portal: Synchronisation du dossier {dossier_data.get('reference', 'INCONNU')}")
        return {
            "success": True,
            "sync_id": "gov-sync-123456789",
            "status": "synchronized"
        }
