from rest_framework import serializers
from .models import NdiogoyeChatLog

class NdiogoyeChatLogSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = NdiogoyeChatLog
        fields = ['id', 'session_id', 'message', 'reply', 'intent', 'action', 'created_at', 'user_email', 'user_name']

    def get_user_name(self, obj):
        if obj.user:
            return f"{obj.user.first_name} {obj.user.last_name}".strip() or "Inconnu"
        return "Anonyme"
