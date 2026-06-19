"""
Views for QR Code public verification with cryptographic validation.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny

from drf_spectacular.utils import extend_schema, OpenApiParameter

from ..dossiers.models import Dossier
from ..documents.models import GeneratedCertificate
from ..documents.crypto import build_payload, verify_signature
from ..shared.responses import success_response, error_response


@extend_schema(
    tags=['QR Code Public Verification'],
    summary="Vérifier l'authenticité d'un document signé",
    description=(
        "Endpoint public (sans authentification). "
        "Vérifie la signature HMAC-SHA256 du certificat et retourne "
        "les données officielles du registre pour comparaison avec le document papier."
    ),
    parameters=[
        OpenApiParameter(
            name='sig', location='query', required=False,
            description='Signature HMAC-SHA256 du certificat (optionnel pour vérification renforcée)'
        ),
    ],
)
@api_view(['GET'])
@permission_classes([AllowAny])
def verify_document(request, reference):
    """
    GET /api/qr/verify/{reference}/?sig=...
    Vérifie l'authenticité d'un certificat via sa référence et optionnellement sa signature.
    """
    # 1. Trouver le dossier
    try:
        dossier = Dossier.objects.select_related('citizen', 'commune').get(
            reference=reference,
            status__in=[Dossier.Status.APPROVED, Dossier.Status.COMPLETED],
        )
    except Dossier.DoesNotExist:
        return error_response(
            message='Document introuvable, invalide ou non approuvé.',
            status_code=status.HTTP_404_NOT_FOUND,
        )

    # 2. Chercher le certificat signé
    try:
        cert = GeneratedCertificate.objects.select_related('officier', 'timbre').get(
            dossier=dossier,
        )
    except GeneratedCertificate.DoesNotExist:
        # Le dossier existe mais pas de certificat signé (ancien système)
        return success_response(
            data={
                'reference': dossier.reference,
                'type': dossier.get_type_display(),
                'status': dossier.get_status_display(),
                'citizen_name': dossier.citizen.full_name,
                'commune': dossier.commune.name if dossier.commune else None,
                'completed_at': dossier.completed_at,
                'crypto_verified': False,
                'message': 'Document trouvé mais non signé cryptographiquement.',
            },
            message='Document trouvé (sans signature cryptographique).',
        )

    # 3. Vérification cryptographique (si signature fournie dans l'URL)
    sig_from_qr = request.query_params.get('sig', '')
    crypto_valid = False

    if sig_from_qr:
        crypto_valid = verify_signature(cert.data_payload, sig_from_qr)

    # 4. Retourner les données officielles
    public_data = {
        'reference': dossier.reference,
        'type': dossier.get_type_display(),
        'status': dossier.get_status_display(),
        'citizen_name': dossier.citizen.full_name,
        'commune': dossier.commune.name if dossier.commune else None,
        'completed_at': dossier.completed_at,
        'officier_name': cert.officier.full_name if cert.officier else None,
        'timbre': cert.timbre.reference if cert.timbre else None,
        'crypto_verified': crypto_valid,
    }

    if crypto_valid:
        return success_response(
            data=public_data,
            message='✅ Document AUTHENTIQUE — Signature cryptographique valide.',
        )
    elif sig_from_qr:
        return success_response(
            data=public_data,
            message='⚠️ ATTENTION — La signature cryptographique ne correspond PAS. Document potentiellement falsifié.',
        )
    else:
        return success_response(
            data=public_data,
            message='Document trouvé. Aucune signature fournie pour vérification renforcée.',
        )
