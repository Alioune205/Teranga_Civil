"""
Validation services for files and documents.
"""
import os
from django.core.exceptions import ValidationError
from .constants import MAX_UPLOAD_SIZE_MB, ALLOWED_EXTENSIONS


def validate_file_size(file_size):
    """Checks if file size is within the allowed limits."""
    max_bytes = MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if file_size > max_bytes:
        raise ValidationError(
            f"Fichier trop volumineux. La taille maximale est de {MAX_UPLOAD_SIZE_MB} Mo."
        )
    return True


def validate_file_extension(filename):
    """Validates the file extension against allowed extensions."""
    ext = filename.rsplit('.', 1)[-1].lower() if '.' in filename else ''
    if ext not in ALLOWED_EXTENSIONS:
        raise ValidationError(
            f"Extension de fichier non autorisée. Extensions permises: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    return ext


def validate_file_signature(file_stream):
    """
    Checks the file magic number header (signature) to prevent spoofing.
    Supported types: PDF, JPEG, PNG.
    """
    # Read first 4 bytes of stream
    file_stream.seek(0)
    header = file_stream.read(4)
    file_stream.seek(0)  # Reset stream position

    if not header:
        raise ValidationError("Le fichier est vide.")

    # Convert to hex signature
    hex_sig = header.hex().upper()

    # Common magic numbers
    # PDF: %PDF -> 25 50 44 46
    # JPEG: FF D8 FF
    # PNG: 89 50 4E 47
    if hex_sig.startswith("25504446"):
        return "pdf"
    elif hex_sig.startswith("FFD8FF"):
        return "jpg"
    elif hex_sig.startswith("89504E47"):
        return "png"
    
    raise ValidationError("Signature de fichier non reconnue (seuls les formats PDF, JPG et PNG sont autorisés).")
