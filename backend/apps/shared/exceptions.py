"""
Custom exception handler for TERANGA CIVIL.
Wraps DRF exceptions into the standardized response format.
"""
from rest_framework.views import exception_handler
from rest_framework import status


def custom_exception_handler(exc, context):
    """
    Custom exception handler that formats all errors consistently.
    """
    response = exception_handler(exc, context)

    if response is not None:
        # Build standardized error response
        error_data = {
            'success': False,
            'message': _get_error_message(response.status_code),
            'data': None,
            'errors': response.data,
        }

        # Handle DRF's detail-style errors
        if isinstance(response.data, dict) and 'detail' in response.data:
            error_data['message'] = str(response.data['detail'])
            error_data['errors'] = None

        response.data = error_data
    else:
        # Log unhandled exceptions
        import logging
        logger = logging.getLogger('system')
        logger.error(f'Unhandled Exception: {str(exc)}', exc_info=True)

    return response


def _get_error_message(status_code):
    """Map HTTP status codes to French error messages."""
    messages = {
        status.HTTP_400_BAD_REQUEST: 'Requête invalide.',
        status.HTTP_401_UNAUTHORIZED: 'Authentification requise.',
        status.HTTP_403_FORBIDDEN: 'Accès interdit.',
        status.HTTP_404_NOT_FOUND: 'Ressource non trouvée.',
        status.HTTP_405_METHOD_NOT_ALLOWED: 'Méthode non autorisée.',
        status.HTTP_409_CONFLICT: 'Conflit de données.',
        status.HTTP_429_TOO_MANY_REQUESTS: 'Trop de requêtes. Veuillez réessayer plus tard.',
        status.HTTP_500_INTERNAL_SERVER_ERROR: 'Erreur interne du serveur.',
    }
    return messages.get(status_code, 'Une erreur est survenue.')
