import time
import logging
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger('system')

class PerformanceMonitoringMiddleware(MiddlewareMixin):
    """
    Middleware qui surveille les temps de réponse de l'API.
    Log automatiquement toute requête dépassant un seuil de latence (Slow Query Log).
    Ceci permet d'identifier les goulots d'étranglement en production.
    """
    
    SLOW_REQUEST_THRESHOLD_MS = 500  # Seuil de 500ms

    def process_request(self, request):
        request.start_time = time.time()

    def process_response(self, request, response):
        # Ne rien faire si la requête n'a pas de start_time (ex: exception critique avant)
        if not hasattr(request, 'start_time'):
            return response

        duration_ms = (time.time() - request.start_time) * 1000

        # Si la requête prend trop de temps, on la logge en WARNING
        if duration_ms > self.SLOW_REQUEST_THRESHOLD_MS:
            # Ne loguer que les requêtes API
            if request.path.startswith('/api/'):
                user = request.user.email if request.user.is_authenticated else 'Anonymous'
                logger.warning(
                    f"[Slow Request] {request.method} {request.path} "
                    f"a pris {duration_ms:.2f}ms. (User: {user})"
                )
        
        # Optionnel: on peut aussi loguer les accès normaux en DEBUG
        logger.debug(
            f"[Request] {request.method} {request.path} - {response.status_code} "
            f"({duration_ms:.2f}ms)"
        )

        return response
