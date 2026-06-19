"""
Serializers for the Notifications app.
"""
from rest_framework import serializers
from .models import Notification, DeviceToken


class NotificationSerializer(serializers.ModelSerializer):
    """Sérialiseur complet d'une notification."""

    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'title', 'message',
            'notification_type', 'channel', 'data',
            'is_read', 'delivered_at', 'created_at',
        ]
        read_only_fields = ['id', 'created_at', 'delivered_at']


class CitizenNotificationSerializer(serializers.ModelSerializer):
    """Sérialiseur pour la liste des notifications du citoyen."""
    body = serializers.CharField(source='message')
    related_dossier_id = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'is_read', 'created_at', 'related_dossier_id']

    def get_related_dossier_id(self, obj):
        return obj.data.get('dossier_id') if isinstance(obj.data, dict) else None


class DeviceTokenSerializer(serializers.ModelSerializer):
    """Sérialiseur pour l'enregistrement d'un token FCM."""

    class Meta:
        model = DeviceToken
        fields = ['id', 'token', 'device_type', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
