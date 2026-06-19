"""
crypto.py — Module de signature cryptographique HMAC-SHA256
===========================================================
Génère et vérifie les signatures qui lient cryptographiquement
le contenu du PDF aux données du dossier.

La faille corrigée : le payload signé inclut le hash SHA-256 du PDF
lui-même, empêchant un faussaire de réutiliser une signature valide
sur un PDF modifié.
"""
import hmac
import hashlib

from django.conf import settings


def _get_signing_key():
    """
    Retourne la clé secrète utilisée pour signer les certificats.
    Utilise SECRET_KEY de Django (256 bits minimum en production).
    """
    return settings.SECRET_KEY.encode('utf-8')


def compute_pdf_hash(pdf_bytes: bytes) -> str:
    """Calcule le hash SHA-256 du contenu binaire du PDF."""
    return hashlib.sha256(pdf_bytes).hexdigest()


def build_payload(
    dossier_reference: str,
    commune_name: str,
    citizen_name: str,
    date_naissance: str,
    officier_id: str,
    pdf_sha256: str,
) -> str:
    """
    Construit le payload canonique à signer.
    Inclut le hash du PDF pour lier la signature au document physique.
    """
    return '|'.join([
        dossier_reference,
        commune_name,
        citizen_name,
        date_naissance,
        str(officier_id),
        pdf_sha256,
    ])


def sign_payload(payload: str) -> str:
    """
    Signe le payload avec HMAC-SHA256 et la clé secrète du serveur.
    Returns:
        str: Signature hexadécimale de 64 caractères.
    """
    return hmac.new(
        _get_signing_key(),
        payload.encode('utf-8'),
        hashlib.sha256,
    ).hexdigest()


def verify_signature(payload: str, signature: str) -> bool:
    """
    Vérifie qu'une signature HMAC correspond au payload donné.
    Utilise hmac.compare_digest pour éviter les timing attacks.
    """
    expected = sign_payload(payload)
    return hmac.compare_digest(expected, signature)
