"""
Serializers for AuditLog.
"""
from rest_framework import serializers
from .models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for reading audit logs."""
    user_email = serializers.CharField(source='user.email', read_only=True, default=None)
    user_name = serializers.CharField(source='user.full_name', read_only=True, default=None)
    action_display = serializers.CharField(source='get_action_display', read_only=True)

    class Meta:
        model = AuditLog
        fields = [
            'id',
            'user',
            'user_email',
            'user_name',
            'user_type',
            'action',
            'action_display',
            'status',
            'resource_type',
            'resource_id',
            'details',
            'ip_address',
            'created_at',
        ]
        read_only_fields = fields
