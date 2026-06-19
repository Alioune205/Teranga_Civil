"""
Utility service for generating unique identifiers.
"""
import uuid
import time
from datetime import datetime


def generate_dossier_reference(prefix='DOS'):
    """
    Generates a unique, standardized dossier reference.
    Format: PREFIX-YYYY-XXXX (e.g. DEC-2026-A4E2)
    """
    year = datetime.now().year
    unique_hex = uuid.uuid4().hex[:5].upper()
    return f"{prefix}-{year}-{unique_hex}"


def generate_transaction_id():
    """
    Generates a unique transaction identifier for services/payments.
    Format: TXN-Timestamp-Random (e.g. TXN-1717589223-9F8)
    """
    timestamp = int(time.time())
    unique_hex = uuid.uuid4().hex[:3].upper()
    return f"TXN-{timestamp}-{unique_hex}"


def generate_agent_badge_number(commune_code):
    """
    Generates an administrative badge number for commune agents.
    Format: COMMUNE-AGENT-XXXX (e.g. DK-AGT-7B4F)
    """
    cleaned_code = str(commune_code)[:4].upper()
    unique_hex = uuid.uuid4().hex[:4].upper()
    return f"{cleaned_code}-AGT-{unique_hex}"
