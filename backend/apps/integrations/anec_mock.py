"""
Mock pour l'Agence Nationale de l'Etat Civil (ANEC).

Simule la vérification de CNI et la récupération d'informations citoyennes.
En production, remplacer par l'API ANEC réelle.
"""
import re
import time
import uuid
from .base import BaseMockClient


class ANECMockClient(BaseMockClient):
    """
    Client de simulation pour l'ANEC.

    Méthodes disponibles :
        - ping() : vérifier la disponibilité du service
        - verify_cni(cni_number) : valider un numéro CNI
        - get_civil_record(record_type, reference) : récupérer un acte d'état civil
    """

    def __init__(self):
        super().__init__("ANEC")

    def ping(self):
        return {"status": "up", "latency": "45ms", "service": "ANEC"}

    def verify_cni(self, cni_number):
        """
        Vérifie la validité d'un numéro de Carte Nationale d'Identité.

        Args:
            cni_number: Numéro de CNI à vérifier.

        Returns:
            dict: Résultat de la vérification avec données citoyennes si valide.
        """
        self.log_call("verify_cni", {"cni_number": cni_number})

        # Validation du format
        if not cni_number or not isinstance(cni_number, str):
            return {
                "success": False,
                "error_code": "INVALID_FORMAT",
                "error": "Le numéro de CNI est requis et doit être une chaîne de caractères.",
            }

        # Simulation : les numéros commençant par '0' sont invalides
        if str(cni_number).startswith('0'):
            return {
                "success": False,
                "error_code": "CNI_NOT_FOUND",
                "error": "CNI invalide ou introuvable dans le registre national.",
            }

        # Simulation de latence réseau
        time.sleep(0.3)

        return {
            "success": True,
            "data": {
                "cni_number": cni_number,
                "first_name": "Amadou",
                "last_name": "Diallo",
                "date_of_birth": "1985-03-22",
                "place_of_birth": "Dakar",
                "gender": "M",
                "is_active": True,
                "expiry_date": "2028-03-22",
            }
        }

    def get_civil_record(self, record_type, reference):
        """
        Récupère un acte d'état civil depuis le registre ANEC.

        Args:
            record_type: Type d'acte ('birth', 'marriage', 'death').
            reference: Numéro de référence de l'acte.

        Returns:
            dict: Données de l'acte si trouvé.
        """
        self.log_call("get_civil_record", {
            "record_type": record_type, "reference": reference,
        })

        valid_types = ('birth', 'marriage', 'death')
        if record_type not in valid_types:
            return {
                "success": False,
                "error_code": "INVALID_TYPE",
                "error": f"Type d'acte invalide. Types acceptés : {', '.join(valid_types)}.",
            }

        time.sleep(0.4)

        return {
            "success": True,
            "data": {
                "reference": reference,
                "record_type": record_type,
                "registry_number": f"REG-{uuid.uuid4().hex[:8].upper()}",
                "is_verified": True,
                "issued_at": "2024-01-15",
            }
        }
