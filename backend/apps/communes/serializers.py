"""
Serializers for Commune.
"""
from rest_framework import serializers
from .models import Commune, Mairie


class CommuneSerializer(serializers.ModelSerializer):
    """Full serializer for Commune."""

    class Meta:
        model = Commune
        fields = [
            'id',
            'name',
            'region',
            'department',
            'code',
            'address',
            'phone',
            'email',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CommuneListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for commune lists."""

    class Meta:
        model = Commune
        fields = ['id', 'name', 'region', 'department', 'code', 'is_active']
        read_only_fields = fields


class MairieSerializer(serializers.ModelSerializer):
    commune_nom = serializers.CharField(source='commune.name', read_only=True)
    region_nom = serializers.CharField(source='commune.region', read_only=True)

    class Meta:
        model = Mairie
        fields = [
            'id', 'nom', 'commune', 'commune_nom', 'region_nom',
            'adresse', 'latitude', 'longitude',
            'telephone', 'email', 'horaires', 'est_active'
        ]

class MairieAvecDistanceSerializer(MairieSerializer):
    distance_km = serializers.FloatField(read_only=True)

    class Meta(MairieSerializer.Meta):
        fields = MairieSerializer.Meta.fields + ['distance_km']
