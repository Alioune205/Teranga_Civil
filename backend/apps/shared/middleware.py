"""
Custom middlewares for TERANGA CIVIL.
"""
from django.utils.deprecation import MiddlewareMixin
from apps.shared.utils import get_client_ip


class AuditLogMiddleware(MiddlewareMixin):
    """
    Middleware that automatically logs sensitive actions using AuditLog.
    """

    def process_response(self, request, response):
        """
        Log after the response is generated to ensure the action succeeded.
        """
        # Only log successful or client error responses (2xx, 4xx)
        if 200 <= response.status_code < 500:
            if hasattr(request, 'audit_log_data') and request.audit_log_data:
                # To prevent circular imports, we import the model inside the method
                from apps.audit_logs.models import AuditLog
                
                user = getattr(request, 'user', None)
                if user and not user.is_authenticated:
                    user = None

                AuditLog.log(
                    user=user,
                    action=request.audit_log_data.get('action', AuditLog.Action.CREATE),
                    resource_type=request.audit_log_data.get('resource_type', 'unknown'),
                    resource_id=request.audit_log_data.get('resource_id'),
                    details=request.audit_log_data.get('details', {}),
                    ip_address=get_client_ip(request),
                )
        return response
