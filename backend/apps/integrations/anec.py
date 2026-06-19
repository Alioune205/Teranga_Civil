"""
ANEC (Agence Nationale de l'État Civil) Integration Service Stub.
"""
import logging
from .base import BaseIntegrationService

logger = logging.getLogger('apps.integrations.anec')


class ANECIntegrationStub(BaseIntegrationService):
    """
    Stub implementation for integrations with ANEC.
    Returns simulated/mock data for hackathon and testing purposes.
    """

    def authenticate(self):
        logger.info(f"Authentification à ANEC (URL: {self.api_url or 'https://api.anec.gov.sn'}) réussie.")
        return {"authenticated": True, "token": "stub-anec-session-token"}

    def fetch_citizen_data(self, cni_number):
        logger.info(f"ANEC: Recherche de l'identité pour la CNI: {cni_number}")
        
        # Simple validation check matching standard validation patterns
        if not cni_number or len(cni_number) < 10:
            return {"success": False, "error": "Numéro CNI invalide"}

        # Return mock citizen details
        return {
            "success": True,
            "source": "ANEC Registry",
            "data": {
                "cni_number": cni_number,
                "first_name": "Awa",
                "last_name": "Ndiaye",
                "date_of_birth": "1994-04-12",
                "place_of_birth": "Dakar Plateau",
                "gender": "F",
                "nationality": "Sénégalaise",
                "status": "active"
            }
        }

    def verify_civil_status_record(self, record_id, record_type):
        logger.info(f"ANEC: Vérification du registre d'état civil ID: {record_id} (Type: {record_type})")
        return {
            "success": True,
            "record_id": record_id,
            "record_type": record_type,
            "verified": True,
            "match_found": True,
            "details": {
                "declared_at": "1994-04-15",
                "officer_name": "Mamadou Fall",
                "commune": "Dakar Plateau"
            }
        }

    def transmit_dossier(self, dossier_data):
        logger.info(f"ANEC: Transmission du dossier {dossier_data.get('reference', 'INCONNU')}")
        return {
            "success": True,
            "transmission_id": "anec-txn-987654321",
            "status": "archived"
        }
