"""
Standardized API responses for TERANGA CIVIL.
"""
from rest_framework.response import Response
from rest_framework import status


def success_response(data=None, message='Opération réussie.', status_code=status.HTTP_200_OK):
    """Return a standardized success response."""
    return Response(
        {
            'success': True,
            'message': message,
            'data': data,
            'errors': None,
        },
        status=status_code,
    )


def created_response(data=None, message='Ressource créée avec succès.'):
    """Return a standardized 201 Created response."""
    return success_response(data=data, message=message, status_code=status.HTTP_201_CREATED)


def error_response(errors=None, message='Une erreur est survenue.', status_code=status.HTTP_400_BAD_REQUEST):
    """Return a standardized error response."""
    return Response(
        {
            'success': False,
            'message': message,
            'data': None,
            'errors': errors,
        },
        status=status_code,
    )


def not_found_response(message='Ressource non trouvée.'):
    """Return a standardized 404 response."""
    return error_response(message=message, status_code=status.HTTP_404_NOT_FOUND)


def forbidden_response(message='Accès interdit.'):
    """Return a standardized 403 response."""
    return error_response(message=message, status_code=status.HTTP_403_FORBIDDEN)
