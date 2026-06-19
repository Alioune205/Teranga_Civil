"""
Views for AuditLog — read-only, super admin access only.
"""
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema_view, extend_schema

from apps.shared.permissions import IsSuperAdmin
from apps.shared.responses import success_response

from .models import AuditLog
from .serializers import AuditLogSerializer
from apps.shared.permissions import IsSuperAdmin, IsCivilAdminSupervisor
from apps.dossiers.models import Dossier
from apps.users.models import User


import django_filters
from django.db.models import Q

class AuditLogFilter(django_filters.FilterSet):
    date_from = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    date_to = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='lte')
    suspect = django_filters.BooleanFilter(method='filter_suspect')

    class Meta:
        model = AuditLog
        fields = ['action', 'resource_type', 'user', 'status', 'user_type']

    def filter_suspect(self, queryset, name, value):
        if value:
            # Events considered suspect: failures, errors, anonymous actions
            return queryset.filter(
                Q(status__in=[AuditLog.Status.FAILURE, AuditLog.Status.ERROR]) |
                Q(user_type=AuditLog.UserType.ANONYMOUS)
            )
        return queryset

@extend_schema_view(
    list=extend_schema(tags=['Audit Logs'], summary='Lister les logs d\'audit'),
    retrieve=extend_schema(tags=['Audit Logs'], summary='Détail d\'un log'),
)
class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only ViewSet for audit logs.
    Super admin only.
    """
    queryset = AuditLog.objects.select_related('user').all()
    serializer_class = AuditLogSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin | IsCivilAdminSupervisor]
    filterset_class = AuditLogFilter
    search_fields = ['user__email', 'resource_type', 'details']
    ordering_fields = ['created_at', 'action']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        
        if user.role == 'super_admin':
            return qs
            
        if user.role == 'civil_admin_supervisor' and user.commune:
            commune_id = user.commune_id
            
            # Sous-requêtes pour trouver les UUIDs correspondant à la commune
            dossiers_ids = Dossier.objects.filter(commune_id=commune_id).values('id')
            users_ids = User.objects.filter(commune_id=commune_id).values('id')
            
            return qs.filter(
                Q(user__commune_id=commune_id) | 
                Q(resource_type='dossier', resource_id__in=dossiers_ids) |
                Q(resource_type='user', resource_id__in=users_ids)
            )
            
        return qs.none()

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return success_response(data=serializer.data)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)
