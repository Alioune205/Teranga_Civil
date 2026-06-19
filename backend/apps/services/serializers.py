"""
Services serializers — Paiements, Signalements, Sondages.
"""
from rest_framework import serializers
from .models import Transaction, Report, Survey, SurveyOption, SurveyVote


# =============================================================================
# PAIEMENTS
# =============================================================================

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer pour les transactions de paiement."""
    citizen_name = serializers.CharField(source='citizen.full_name', read_only=True)
    provider_display = serializers.CharField(source='get_provider_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Transaction
        fields = [
            'id', 'reference', 'citizen', 'citizen_name', 'dossier',
            'provider', 'provider_display', 'amount', 'phone_number',
            'status', 'status_display', 'external_transaction_id',
            'receipt_url', 'paid_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'reference', 'citizen', 'status', 'external_transaction_id', 'receipt_url', 'paid_at', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['citizen'] = self.context['request'].user
        return super().create(validated_data)


# =============================================================================
# SIGNALEMENTS
# =============================================================================

class ReportSerializer(serializers.ModelSerializer):
    """Serializer pour les signalements citoyens."""
    citizen_name = serializers.CharField(source='citizen.full_name', read_only=True)
    commune_name = serializers.CharField(source='commune.name', read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Report
        fields = [
            'id', 'citizen', 'citizen_name', 'commune', 'commune_name',
            'category', 'category_display', 'title', 'description',
            'status', 'status_display', 'latitude', 'longitude',
            'photo', 'admin_notes', 'resolved_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'citizen', 'status', 'admin_notes', 'resolved_at', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['citizen'] = self.context['request'].user
        return super().create(validated_data)


class ReportAdminUpdateSerializer(serializers.ModelSerializer):
    """Serializer pour la mise à jour des signalements par l'administration."""
    class Meta:
        model = Report
        fields = ['status', 'admin_notes', 'resolved_at']


# =============================================================================
# SONDAGES
# =============================================================================

class SurveyOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = SurveyOption
        fields = ['id', 'text', 'votes_count']
        read_only_fields = ['id', 'votes_count']


class SurveySerializer(serializers.ModelSerializer):
    """Serializer pour les sondages avec leurs options."""
    options = SurveyOptionSerializer(many=True, read_only=True)
    commune_name = serializers.CharField(source='commune.name', read_only=True)
    creator_name = serializers.CharField(source='created_by.full_name', read_only=True)
    is_open = serializers.BooleanField(read_only=True)

    class Meta:
        model = Survey
        fields = [
            'id', 'commune', 'commune_name', 'title', 'description',
            'starts_at', 'ends_at', 'is_open', 'options',
            'creator_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class SurveyVoteSerializer(serializers.ModelSerializer):
    """Serializer pour voter à un sondage."""
    class Meta:
        model = SurveyVote
        fields = ['survey', 'option']

    def validate(self, data):
        survey = data['survey']
        option = data['option']
        
        if option.survey != survey:
            raise serializers.ValidationError("Cette option n'appartient pas à ce sondage.")
            
        if not survey.is_open:
            raise serializers.ValidationError("Ce sondage n'est pas ouvert.")
            
        user = self.context['request'].user
        if SurveyVote.objects.filter(survey=survey, citizen=user).exists():
            raise serializers.ValidationError("Vous avez déjà voté pour ce sondage.")
            
        return data
