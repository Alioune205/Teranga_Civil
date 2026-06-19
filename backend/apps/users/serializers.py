"""
Serializers for User and CitizenProfile.
"""
from rest_framework import serializers

from .models import User, CitizenProfile


class CitizenProfileSerializer(serializers.ModelSerializer):
    """Serializer for CitizenProfile model."""

    class Meta:
        model = CitizenProfile
        fields = [
            'id',
            'address',
            'cni_number',
            'date_of_birth',
            'place_of_birth',
            'gender',
            'profession',
            'photo',
            'cni_document',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    """Serializer for reading User data."""
    profile = CitizenProfileSerializer(read_only=True)
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'phone',
            'first_name',
            'last_name',
            'full_name',
            'role',
            'commune',
            'avatar',
            'is_verified',
            'is_active',
            'is_on_break',
            'break_started_at',
            'is_dispatch_eligible',
            'profile',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id', 'email', 'role', 'is_verified',
            'created_at', 'updated_at',
        ]


class UserListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for user lists (no nested profile)."""
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'phone',
            'first_name',
            'last_name',
            'full_name',
            'role',
            'commune',
            'avatar',
            'is_active',
            'is_on_break',
            'break_started_at',
            'is_dispatch_eligible',
            'last_login',
            'is_verified',
            'created_at',
        ]
        read_only_fields = fields


class UserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating User data (limited fields)."""

    class Meta:
        model = User
        fields = [
            'phone',
            'first_name',
            'last_name',
            'commune',
            'avatar',
        ]


class ChangePasswordSerializer(serializers.Serializer):
    password = serializers.CharField(write_only=True, required=True)

class UserCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new Users."""
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'email',
            'password',
            'phone',
            'first_name',
            'last_name',
            'role',
            'commune',
        ]

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        # Agents are verified by default when created by admins
        user.is_verified = True
        user.save()
        return user


class CitizenProfileDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for CitizenProfile with nested user info."""
    user = UserListSerializer(read_only=True)

    class Meta:
        model = CitizenProfile
        fields = [
            'id',
            'user',
            'address',
            'cni_number',
            'date_of_birth',
            'place_of_birth',
            'gender',
            'profession',
            'photo',
            'cni_document',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
