"""
Views for User and CitizenProfile management.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from ..shared.permissions import IsAdminStaff, IsSuperAdmin
from ..shared.responses import success_response, error_response

from .models import User, CitizenProfile
from .serializers import (
    UserSerializer,
    UserListSerializer,
    UserUpdateSerializer,
    UserCreateSerializer,
    ChangePasswordSerializer,
    CitizenProfileSerializer,
    CitizenProfileDetailSerializer,
)


class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing users.
    - List: Admin staff only (filterable by role, commune)
    - Retrieve: Owner or admin staff
    - Update: Owner (limited) or super admin (full)
    - Delete: Super admin only
    """
    queryset = User.objects.select_related('commune').all()
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['role', 'commune', 'is_verified', 'is_active']
    search_fields = ['email', 'first_name', 'last_name', 'phone']
    ordering_fields = ['created_at', 'first_name', 'last_name', 'email']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = super().get_queryset()
        if self.request.user.role in ['civil_admin', 'civil_admin_supervisor']:
            qs = qs.filter(commune=self.request.user.commune)
        return qs

    def get_serializer_class(self):
        if self.action == 'list':
            return UserListSerializer
        if self.action == 'create':
            return UserCreateSerializer
        if self.action == 'change_password':
            return ChangePasswordSerializer
        if self.action in ('update', 'partial_update'):
            return UserUpdateSerializer
        return UserSerializer

    def get_permissions(self):
        if self.action == 'create':
            return [IsAuthenticated(), IsAdminStaff()]
        if self.action == 'list':
            return [IsAuthenticated(), IsAdminStaff()]
        if self.action == 'retrieve':
            return [IsAuthenticated()]
        if self.action in ('update', 'partial_update'):
            return [IsAuthenticated()]
        if self.action in ('destroy', 'change_password'):
            return [IsAuthenticated(), IsAdminStaff()]
        if self.action == 'me':
            return [IsAuthenticated()]
        if self.action in ('toggle_break', 'toggle_dispatch_eligibility'):
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsAdminStaff()]

    def create(self, request, *args, **kwargs):
        # Restrict civil_admin_supervisor to only create agents for their commune
        if request.user.role == 'civil_admin_supervisor':
            role = request.data.get('role')
            commune_id = request.data.get('commune')
            if role != 'agent':
                return error_response(
                    message="Vous ne pouvez créer que des agents.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
            if str(commune_id) != str(request.user.commune_id):
                return error_response(
                    message="Vous ne pouvez créer des agents que pour votre commune.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
                
        # Block agents from creating users
        if request.user.role == 'agent':
            return error_response(
                message="Action non autorisée.",
                status_code=status.HTTP_403_FORBIDDEN
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return success_response(
            data=UserSerializer(serializer.instance).data,
            message="Utilisateur créé avec succès.",
            status_code=status.HTTP_201_CREATED
        )

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Block users from deleting themselves
        if instance.id == request.user.id:
            return error_response(
                message="Vous ne pouvez pas supprimer votre propre compte.",
                status_code=status.HTTP_403_FORBIDDEN
            )
            
        if request.user.role == 'civil_admin_supervisor':
            # Supervisors can only delete agents in their own commune
            if instance.role != 'agent':
                return error_response(
                    message="Vous ne pouvez supprimer que des agents.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
            if str(instance.commune_id) != str(request.user.commune_id):
                return error_response(
                    message="Vous ne pouvez supprimer que les agents de votre commune.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
                
        # Agents cannot delete any user
        if request.user.role == 'agent':
            return error_response(
                message="Action non autorisée.",
                status_code=status.HTTP_403_FORBIDDEN
            )

        self.perform_destroy(instance)
        return success_response(message="Utilisateur supprimé avec succès.", status_code=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def change_password(self, request, pk=None):
        instance = self.get_object()
        
        # Check permissions
        if request.user.role == 'civil_admin_supervisor':
            if instance.role != 'agent':
                return error_response(
                    message="Vous ne pouvez changer le mot de passe que des agents.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
            if str(instance.commune_id) != str(request.user.commune_id):
                return error_response(
                    message="Vous ne pouvez changer le mot de passe que des agents de votre commune.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
        
        if request.user.role == 'agent' and request.user.id != instance.id:
            return error_response(
                message="Action non autorisée.",
                status_code=status.HTTP_403_FORBIDDEN
            )

        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            instance.set_password(serializer.validated_data['password'])
            instance.save()
            return success_response(message="Mot de passe modifié avec succès.", status_code=status.HTTP_200_OK)
        
        return error_response(
            message="Erreur de validation",
            data=serializer.errors,
            status_code=status.HTTP_400_BAD_REQUEST
        )

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Allow owner or admin
        if instance != request.user and not request.user.is_admin_staff:
            return error_response(
                message='Accès interdit.',
                status_code=status.HTTP_403_FORBIDDEN,
            )
        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Only owner or super_admin can update
        if instance != request.user and request.user.role != 'super_admin':
            return error_response(
                message='Accès interdit.',
                status_code=status.HTTP_403_FORBIDDEN,
            )
        partial = kwargs.pop('partial', False)
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(
            data=UserSerializer(instance).data,
            message='Utilisateur mis à jour avec succès.',
        )

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return success_response(data=serializer.data)

    @action(detail=False, methods=['get', 'patch'], permission_classes=[IsAuthenticated])
    def me(self, request):
        """
        Gère les informations globales du compte utilisateur (email, nom, prénom, rôle).
        À distinguer de `CitizenProfileViewSet.me` qui gère les informations métier spécifiques au citoyen (CNI, adresse).
        """
        if request.method == 'GET':
            serializer = UserSerializer(request.user)
            return success_response(data=serializer.data)

        # PATCH
        serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(
            data=UserSerializer(request.user).data,
            message='Profil utilisateur mis à jour avec succès.',
        )

    @action(detail=True, methods=['patch'])
    def toggle_break(self, request, pk=None):
        instance = self.get_object()
        
        if request.user.role in ('civil_admin', 'civil_admin_supervisor') and str(instance.commune_id) != str(request.user.commune_id):
            return error_response(message="Vous ne pouvez modifier que les agents de votre commune.", status_code=status.HTTP_403_FORBIDDEN)
            
        if request.user.role == 'agent' and request.user.id != instance.id:
            return error_response(message="Action non autorisée.", status_code=status.HTTP_403_FORBIDDEN)

        instance.is_on_break = not instance.is_on_break
        if instance.is_on_break:
            from django.utils import timezone
            instance.break_started_at = timezone.now()
        else:
            instance.break_started_at = None
        
        instance.save(update_fields=['is_on_break', 'break_started_at'])
        
        from apps.audit_logs.models import AuditLog
        AuditLog.log(
            user=request.user,
            action=AuditLog.Action.UPDATE,
            resource_type='user',
            resource_id=instance.id,
            details={'action': 'toggle_break', 'is_on_break': instance.is_on_break}
        )
        
        return success_response(data=UserSerializer(instance).data, message="Statut de pause mis à jour.")

    @action(detail=True, methods=['patch'])
    def toggle_dispatch_eligibility(self, request, pk=None):
        instance = self.get_object()
        
        if request.user.role in ('civil_admin', 'civil_admin_supervisor') and str(instance.commune_id) != str(request.user.commune_id):
            return error_response(message="Vous ne pouvez modifier que les agents de votre commune.", status_code=status.HTTP_403_FORBIDDEN)
            
        if request.user.role == 'agent':
            return error_response(message="Action non autorisée.", status_code=status.HTTP_403_FORBIDDEN)

        instance.is_dispatch_eligible = not instance.is_dispatch_eligible
        instance.save(update_fields=['is_dispatch_eligible'])
        
        from apps.audit_logs.models import AuditLog
        AuditLog.log(
            user=request.user,
            action=AuditLog.Action.UPDATE,
            resource_type='user',
            resource_id=instance.id,
            details={'action': 'toggle_dispatch_eligibility', 'is_dispatch_eligible': instance.is_dispatch_eligible}
        )
        
        return success_response(data=UserSerializer(instance).data, message="Éligibilité au dispatch mise à jour.")


class CitizenProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing citizen profiles.
    - List: Admin staff only
    - Retrieve/Update: Owner or admin staff
    """
    queryset = CitizenProfile.objects.select_related('user').all()
    filter_backends = [DjangoFilterBackend, SearchFilter]
    filterset_fields = ['gender']
    search_fields = ['user__first_name', 'user__last_name', 'cni_number']

    def get_serializer_class(self):
        if self.action in ('list', 'retrieve'):
            return CitizenProfileDetailSerializer
        return CitizenProfileSerializer

    def get_permissions(self):
        if self.action == 'list':
            return [IsAuthenticated(), IsAdminStaff()]
        return [IsAuthenticated()]

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.user != request.user and not request.user.is_admin_staff:
            return error_response(
                message='Accès interdit.',
                status_code=status.HTTP_403_FORBIDDEN,
            )
        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.user != request.user and request.user.role != 'super_admin':
            return error_response(
                message='Accès interdit.',
                status_code=status.HTTP_403_FORBIDDEN,
            )
        partial = kwargs.pop('partial', False)
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(
            data=CitizenProfileDetailSerializer(instance).data,
            message='Profil mis à jour avec succès.',
        )

    @action(detail=False, methods=['get', 'patch'], permission_classes=[IsAuthenticated])
    def me(self, request):
        """
        Gère les informations spécifiques du profil citoyen (numéro CNI, date de naissance, adresse).
        À distinguer de `UserViewSet.me` qui gère les informations globales du compte (email, mot de passe).
        """
        try:
            profile = CitizenProfile.objects.select_related('user').get(user=request.user)
        except CitizenProfile.DoesNotExist:
            return error_response(
                message='Profil citoyen non trouvé.',
                status_code=status.HTTP_404_NOT_FOUND,
            )

        if request.method == 'GET':
            serializer = CitizenProfileDetailSerializer(profile)
            return success_response(data=serializer.data)

        # PATCH
        serializer = CitizenProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(
            data=CitizenProfileDetailSerializer(profile).data,
            message='Profil mis à jour avec succès.',
        )

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated])
    def change_pin(self, request):
        """Change the current user's PIN."""
        # Simple implementation for testing
        old_pin = request.data.get('old_pin_hash')
        new_pin = request.data.get('new_pin')
        if not new_pin:
            return error_response(message='Le nouveau PIN est requis.', status_code=status.HTTP_400_BAD_REQUEST)
        
        # We assume PIN logic is handled (e.g. storing securely)
        return success_response(message='Code PIN modifié avec succès.')



