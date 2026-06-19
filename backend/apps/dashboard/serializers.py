"""
Dashboard serializers — Statistiques et rapports pour le Dashboard administratif.
"""
from rest_framework import serializers
from apps.dossiers.models import Dossier
from apps.users.models import User


class DossierCountByStatusSerializer(serializers.Serializer):
    """Nombre de dossiers par statut."""
    status = serializers.CharField()
    status_display = serializers.CharField()
    count = serializers.IntegerField()


class DossierCountByTypeSerializer(serializers.Serializer):
    """Nombre de dossiers par type."""
    type = serializers.CharField()
    type_display = serializers.CharField()
    count = serializers.IntegerField()


class DossierCountByCommuneSerializer(serializers.Serializer):
    """Nombre de dossiers par commune."""
    commune__name = serializers.CharField()
    commune__region = serializers.CharField()
    count = serializers.IntegerField()


class DailyVolumeSerializer(serializers.Serializer):
    """Volume de dossiers par jour."""
    date = serializers.DateField()
    count = serializers.IntegerField()


class AgentPerformanceSerializer(serializers.Serializer):
    """Performance d'un agent (dossiers traités, délai moyen)."""
    agent_id = serializers.UUIDField()
    agent_name = serializers.CharField()
    agent_role = serializers.CharField()
    total_assigned = serializers.IntegerField()
    total_completed = serializers.IntegerField()
    total_rejected = serializers.IntegerField()
    avg_processing_hours = serializers.FloatField(allow_null=True)


class OverviewStatsSerializer(serializers.Serializer):
    """Vue d'ensemble des statistiques globales."""
    total_dossiers = serializers.IntegerField()
    total_pending = serializers.IntegerField()
    total_in_review = serializers.IntegerField()
    total_approved = serializers.IntegerField()
    total_rejected = serializers.IntegerField()
    total_completed = serializers.IntegerField()
    total_citizens = serializers.IntegerField()
    total_agents = serializers.IntegerField()
    avg_processing_hours = serializers.FloatField(allow_null=True)
    completion_rate = serializers.FloatField()


class RecentDossierSerializer(serializers.Serializer):
    """Dossier récent simplifié pour le dashboard."""
    id = serializers.UUIDField()
    reference = serializers.CharField()
    type = serializers.CharField()
    type_display = serializers.CharField()
    status = serializers.CharField()
    status_display = serializers.CharField()
    citizen_name = serializers.CharField()
    commune_name = serializers.CharField()
    created_at = serializers.DateTimeField()
    submitted_at = serializers.DateTimeField(allow_null=True)


class ProcessingDelaySerializer(serializers.Serializer):
    """Délais de traitement par type de dossier."""
    type = serializers.CharField()
    type_display = serializers.CharField()
    avg_hours = serializers.FloatField(allow_null=True)
    min_hours = serializers.FloatField(allow_null=True)
    max_hours = serializers.FloatField(allow_null=True)
    total_processed = serializers.IntegerField()
