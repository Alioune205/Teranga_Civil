from django.http import JsonResponse
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.exceptions import AuthenticationFailed

class ReadOnlyForSuperAdminMiddleware:
    """
    Middleware qui bloque les actions d'écriture (POST, PUT, PATCH, DELETE)
    si le rôle de l'utilisateur dans le token JWT est 'super_admin'.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Autoriser les méthodes de consultation sûres
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return self.get_response(request)

        # Exempter explicitement les endpoints d'authentification et les actions citoyen pour le test
        exempt_prefixes = [
            '/api/auth/',
            '/api/v1/auth/super-admin/',
            '/api/citoyens/',
            '/api/dossiers/',
            '/api/attribution/',
            '/api/notifications/',
            '/api/ai/'
        ]
        path = request.path
        if any(path.startswith(prefix) for prefix in exempt_prefixes):
            return self.get_response(request)

        # Extraire l'utilisateur du request ou du token JWT
        user = None
        if hasattr(request, 'user') and request.user.is_authenticated:
            user = request.user
        else:
            try:
                jwt_auth = JWTAuthentication()
                auth_result = jwt_auth.authenticate(request)
                if auth_result:
                    user = auth_result[0]
            except AuthenticationFailed:
                pass

        # Si l'utilisateur est super_admin, refuser les requêtes de mutation (403 Forbidden)
        if user and hasattr(user, 'role') and user.role == 'super_admin':
            return JsonResponse({
                'success': False,
                'message': 'Mode lecture seule — Toute modification est désactivée conformément aux règles de la Trésorerie Publique.',
                'errors': 'Forbidden'
            }, status=403)

        return self.get_response(request)
