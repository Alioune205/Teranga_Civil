from rest_framework.permissions import BasePermission

class IsAgent(BasePermission):
    """Seul l'agent polyvalent peut traiter et soumettre un dossier."""
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and
            request.user.role == 'agent'
        )

class IsSuperviseur(BasePermission):
    """Seul le Superviseur peut approuver ou rejeter un dossier."""
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and
            request.user.role == 'civil_admin_supervisor'
        )
