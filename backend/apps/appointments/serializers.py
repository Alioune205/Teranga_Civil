from rest_framework import serializers
from apps.appointments.models import Appointment
from apps.users.serializers import UserListSerializer
from apps.dossiers.serializers import DossierListSerializer

class AppointmentSerializer(serializers.ModelSerializer):
    citizen = UserListSerializer(read_only=True)
    agent = UserListSerializer(read_only=True)
    dossier = DossierListSerializer(read_only=True)

    class Meta:
        model = Appointment
        fields = '__all__'

class AppointmentScheduleSerializer(serializers.Serializer):
    scheduled_date = serializers.DateTimeField(required=True)
    agent_id = serializers.UUIDField(required=False, allow_null=True)

class AppointmentCancelSerializer(serializers.Serializer):
    cancel_reason = serializers.CharField(required=False, allow_blank=True)

from apps.dossiers.models import Dossier

class AppointmentCreateSerializer(serializers.ModelSerializer):
    dossier_id = serializers.PrimaryKeyRelatedField(
        queryset=Dossier.objects.all(),
        source='dossier',
        write_only=True
    )

    class Meta:
        model = Appointment
        fields = ['id', 'dossier_id', 'reason']

    def validate_dossier_id(self, value):
        request = self.context.get('request')
        if request and request.user.role == 'citizen' and value.citizen != request.user:
            raise serializers.ValidationError("Vous ne pouvez pas demander un rendez-vous pour un dossier qui ne vous appartient pas.")
        return value
