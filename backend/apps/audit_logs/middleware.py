import logging
from django.utils.deprecation import MiddlewareMixin
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.exceptions import AuthenticationFailed

from .models import AuditLog

logger = logging.getLogger(__name__)


class AuditLogMiddleware(MiddlewareMixin):
    """
    Middleware qui intercepte les requêtes de modification
    (POST, PUT, PATCH, DELETE) et crée automatiquement un log d'audit.
    """

    def process_response(self, request, response):
        # On logue toutes les requêtes modifiantes (succès ou échec)
        if request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            # Déterminer le statut
            if 200 <= response.status_code < 400:
                log_status = AuditLog.Status.SUCCESS
            elif 400 <= response.status_code < 500:
                log_status = AuditLog.Status.FAILURE
            else:
                log_status = AuditLog.Status.ERROR
            # Essayer de récupérer l'utilisateur via JWT
            user = None
            if (
                hasattr(request, 'user')
                and request.user.is_authenticated
            ):
                user = request.user
            else:
                try:
                    jwt_auth = JWTAuthentication()
                    auth_result = jwt_auth.authenticate(request)
                    if auth_result:
                        user = auth_result[0]
                except AuthenticationFailed:
                    pass

            # Mappage de la méthode HTTP à l'action
            action_map = {
                'POST': AuditLog.Action.CREATE,
                'PUT': AuditLog.Action.UPDATE,
                'PATCH': AuditLog.Action.UPDATE,
                'DELETE': AuditLog.Action.DELETE,
            }
            action = action_map.get(request.method)

            # Identification du type de ressource par l'URL
            path_parts = [
                p for p in request.path.split('/') if p
            ]
            resource_type = (
                path_parts[1] if len(path_parts) > 1
                else 'unknown'
            )

            # Exceptions / Routes spécifiques
            if 'login' in request.path:
                action = AuditLog.Action.LOGIN
                resource_type = 'auth'
            elif 'logout' in request.path:
                action = AuditLog.Action.LOGOUT
                resource_type = 'auth'
            elif 'upload' in request.path:
                action = AuditLog.Action.UPLOAD

            # Extraction IP
            ip_address = request.META.get(
                'HTTP_X_FORWARDED_FOR'
            )
            if ip_address:
                ip_address = ip_address.split(',')[0]
            else:
                ip_address = request.META.get('REMOTE_ADDR')

            user_type = AuditLog.UserType.USER if user else AuditLog.UserType.ANONYMOUS

            try:
                AuditLog.log(
                    user=user,
                    user_type=user_type,
                    action=action,
                    status=log_status,
                    resource_type=resource_type,
                    details={
                        'path': request.path,
                        'method': request.method,
                        'status_code': response.status_code
                    },
                    ip_address=ip_address
                )
            except Exception as e:
                logger.error(
                    f"Erreur lors de la création du log "
                    f"d'audit : {e}"
                )

        return response
