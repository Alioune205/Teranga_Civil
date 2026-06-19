"""
Custom validators for TERANGA CIVIL.
"""
import re

from django.core.exceptions import ValidationError
from django.conf import settings


def validate_phone_senegal(value):
    """
    Validate Senegalese phone number format.
    Accepts: +221XXXXXXXXX, 221XXXXXXXXX, 7XXXXXXXX, 77XXXXXXX, etc.
    """
    # Remove spaces, dashes, dots
    cleaned = re.sub(r'[\s\-\.]', '', value)

    # Pattern: optional +221 prefix, then 9 digits starting with 7
    pattern = r'^(\+?221)?[7][0-9]{8}$'

    if not re.match(pattern, cleaned):
        raise ValidationError(
            'Numéro de téléphone invalide. '
            'Format attendu : +221 7X XXX XX XX'
        )


def validate_cni(value):
    """
    Validate Senegalese CNI (Carte Nationale d'Identité) number.
    Format: 1 or 2 digits + space + digits (typically 13-digit total).
    """
    cleaned = re.sub(r'[\s\-]', '', value)

    if not cleaned.isdigit():
        raise ValidationError(
            'Le numéro CNI ne doit contenir que des chiffres.'
        )

    if len(cleaned) < 10 or len(cleaned) > 15:
        raise ValidationError(
            'Le numéro CNI doit contenir entre 10 et 15 chiffres.'
        )


def validate_document_file(file):
    """
    Validate uploaded document file (type and size).
    """
    # Check file size
    max_size = getattr(settings, 'MAX_DOCUMENT_SIZE', 10 * 1024 * 1024)
    if file.size > max_size:
        raise ValidationError(
            f'La taille du fichier ne doit pas dépasser '
            f'{max_size // (1024 * 1024)} Mo.'
        )

    # Check file extension
    allowed_types = getattr(
        settings, 'ALLOWED_DOCUMENT_TYPES',
        ['pdf', 'jpg', 'jpeg', 'png']
    )
    ext = file.name.rsplit('.', 1)[-1].lower() if '.' in file.name else ''
    if ext not in allowed_types:
        raise ValidationError(
            f'Type de fichier non autorisé. '
            f'Types acceptés : {", ".join(allowed_types)}'
        )
