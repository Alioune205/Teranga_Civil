"""
RBAC Permission classes for TERANGA CIVIL.
These permissions check the user's role field for access control.
"""
from rest_framework.permissions import BasePermission


class IsRole(BasePermission):
    """
    Base permission class that checks if a user has one of the allowed roles.
    Subclass this and set `allowed_roles` to define specific role permissions.
    """
    allowed_roles = []

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in self.allowed_roles


class IsCitizen(IsRole):
    """Only citizens can access."""
    allowed_roles = ['citizen']
    message = 'Accès réservé aux citoyens.'


class IsAgent(IsRole):
    """Only agents can access."""
    allowed_roles = ['agent']
    message = 'Accès réservé aux agents.'


class IsAgentWithCapability(BasePermission):
    """Base permission class that checks if an agent has a specific capability."""
    required_capability = None

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        # Les super admins ou civil admins ont souvent les permissions implicitement selon la logique métier,
        # mais stricto sensu, pour une action d'agent (ex: valider une étape), on vérifie le rôle agent.
        if request.user.role == 'agent':
            return self.required_capability in request.user.agent_capabilities
        return False

class IsReceptionAgent(IsAgentWithCapability):
    """Only agents with reception capability can access."""
    required_capability = 'reception'
    message = 'Accès réservé aux agents de réception.'


class IsVerificationAgent(IsAgentWithCapability):
    """Only agents with verification capability can access."""
    required_capability = 'verification'
    message = 'Accès réservé aux agents de vérification.'


class IsApprovalAgent(IsAgentWithCapability):
    """Only agents with approval capability can access."""
    required_capability = 'approval'
    message = 'Accès réservé aux agents d\'approbation.'


class IsCivilAdmin(IsRole):
    """Only civil administrators can access."""
    allowed_roles = ['civil_admin']
    message = 'Accès réservé aux administrateurs de mairie (RH).'


class IsCivilAdminSupervisor(IsRole):
    """Only civil admin supervisors can access."""
    allowed_roles = ['civil_admin_supervisor']
    message = 'Accès réservé aux administrateurs généraux.'


class IsSuperAdmin(IsRole):
    """Only super administrators can access."""
    allowed_roles = ['super_admin']
    message = 'Accès réservé aux super administrateurs.'


class IsAdminStaff(IsRole):
    """
    Any administrative staff (agent, civil_admin, civil_admin_supervisor, super_admin) can access.
    """
    allowed_roles = [
        'agent',
        'civil_admin',
        'civil_admin_supervisor',
        'super_admin',
    ]
    message = 'Accès réservé au personnel administratif.'


class IsAdminOrReadOnly(BasePermission):
    """
    Admin staff gets full access; others get read-only.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return request.method in ('GET', 'HEAD', 'OPTIONS')

        if request.method in ('GET', 'HEAD', 'OPTIONS'):
            return True

        return request.user.role in [
            'agent',
            'civil_admin',
            'civil_admin_supervisor',
            'super_admin',
        ]


class IsOwnerOrAdmin(BasePermission):
    """
    Object-level permission: owner of the object or admin staff.
    The object must have a `user` or `citizen` field pointing to the User.
    """
    def has_object_permission(self, request, view, obj):
        # Check if user is admin staff (supervisors included for object reads usually, but write check relies on the view)
        if request.user.role in ['civil_admin', 'civil_admin_supervisor', 'super_admin']:
            return True

        # Check ownership via common FK names
        if hasattr(obj, 'user') and obj.user == request.user:
            return True
        if hasattr(obj, 'citizen') and obj.citizen == request.user:
            return True
        if hasattr(obj, 'uploaded_by') and obj.uploaded_by == request.user:
            return True

        return False
