"""
Serializers for role management.
"""
from rest_framework import serializers

from django.contrib.auth import get_user_model

User = get_user_model()


class RoleSerializer(serializers.Serializer):
    """Serializer for listing available roles."""
    value = serializers.CharField()
    label = serializers.CharField()


class RoleAssignSerializer(serializers.Serializer):
    """Serializer for assigning a role to a user."""
    user_id = serializers.UUIDField(required=True)
    role = serializers.ChoiceField(choices=User.Role.choices, required=True)

    def validate_user_id(self, value):
        try:
            User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError('Utilisateur non trouvé.')
        return value
