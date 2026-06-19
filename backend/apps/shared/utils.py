"""
Utility functions for TERANGA CIVIL.
"""
import uuid
from datetime import datetime


def generate_reference(prefix='REF'):
    """
    Generate a unique reference number.
    Format: PREFIX-YYYY-NNNNN (e.g., DOS-2026-A3F5B)
    """
    year = datetime.now().year
    unique_part = uuid.uuid4().hex[:5].upper()
    return f'{prefix}-{year}-{unique_part}'


def get_client_ip(request):
    """
    Extract the client IP address from the request.
    Handles X-Forwarded-For header for proxied requests.
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR', '0.0.0.0')
