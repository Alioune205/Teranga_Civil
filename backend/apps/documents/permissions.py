"""
Permissions for documents app.
"""
from rest_framework.permissions import BasePermission

class DocumentAccessPermission(BasePermission):
    """
    Permission for downloading/accessing a document.
    """
    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user.is_authenticated:
            return False
            
        if getattr(user, 'role', None) == 'super_admin':
            return True
            
        if getattr(user, 'role', None) == 'citizen':
            return obj.dossier.citizen == user
            
        if getattr(user, 'is_admin_staff', False) and getattr(user, 'commune', None):
            return obj.dossier.commune == user.commune
            
        return False

class IsDocumentOwner(BasePermission):
    """
    Permission allowing only the document owner or admins to delete.
    """
    def has_object_permission(self, request, view, obj):
        user = request.user
        if getattr(user, 'role', None) in ['super_admin', 'civil_admin']:
            return True
        return obj.uploaded_by == user
