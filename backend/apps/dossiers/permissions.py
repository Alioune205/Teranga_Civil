from rest_framework.permissions import BasePermission

class IsAgent(BasePermission):
    def has_permission(self, request, view):
        # We check both to match the DB value ('agent') and the user's requested string ('AGENT')
        return request.user.is_authenticated and request.user.role in ['AGENT', 'agent']

class IsMaire(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'MAIRE'
