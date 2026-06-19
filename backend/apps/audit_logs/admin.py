"""
Admin configuration for AuditLog.
"""
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(ModelAdmin):
    list_display = ('action', 'user', 'resource_type', 'ip_address', 'created_at')
    list_filter = ('action', 'resource_type', 'created_at')
    search_fields = ('user__email', 'resource_type', 'ip_address')
    readonly_fields = ('id', 'user', 'action', 'resource_type', 'resource_id', 'details', 'ip_address', 'created_at')
    ordering = ('-created_at',)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
