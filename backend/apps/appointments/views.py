from django.utils import timezone
from rest_framework import viewsets, status, mixins
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from apps.appointments.models import Appointment
from apps.appointments.serializers import AppointmentSerializer, AppointmentScheduleSerializer, AppointmentCreateSerializer
from apps.shared.responses import success_response, error_response
from apps.shared.permissions import IsCivilAdmin, IsAdminStaff, IsAgent, IsVerificationAgent, IsApprovalAgent, IsReceptionAgent, IsSuperAdmin

class AppointmentViewSet(mixins.CreateModelMixin, mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AppointmentCreateSerializer
        return AppointmentSerializer

    def perform_create(self, serializer):
        serializer.save(citizen=self.request.user, status=Appointment.Status.PENDING)

    
    def get_queryset(self):
        user = self.request.user
        qs = Appointment.objects.select_related('dossier', 'citizen', 'agent')
        if user.role == 'citizen':
            return qs.filter(citizen=user)
        elif user.role in ['agent', 'civil_admin', 'civil_admin_supervisor']:
            if user.commune:
                return qs.filter(dossier__commune=user.commune)
        elif user.role == 'super_admin':
            return qs.all()
        return qs.none()

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsAgent | IsVerificationAgent | IsApprovalAgent | IsReceptionAgent | IsCivilAdmin | IsSuperAdmin])
    def schedule(self, request, pk=None):
        appointment = self.get_object()
        serializer = AppointmentScheduleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        if appointment.status != Appointment.Status.PENDING:
            return error_response(
                message='Seul un rendez-vous en attente peut être programmé.',
                status_code=status.HTTP_400_BAD_REQUEST
            )
            
        appointment.scheduled_date = serializer.validated_data['scheduled_date']
        appointment.status = Appointment.Status.SCHEDULED
        
        assigned_agent_id = serializer.validated_data.get('agent_id')
        if assigned_agent_id:
            if request.user.role not in ['civil_admin', 'civil_admin_supervisor', 'super_admin']:
                return error_response(
                    message="Vous n'avez pas l'autorisation d'assigner ce rendez-vous à un autre agent.",
                    status_code=status.HTTP_403_FORBIDDEN
                )
            
            from django.contrib.auth import get_user_model
            User = get_user_model()
            try:
                assigned_agent = User.objects.get(id=assigned_agent_id)
                appointment.agent = assigned_agent
            except User.DoesNotExist:
                return error_response(
                    message="L'agent spécifié est introuvable.",
                    status_code=status.HTTP_404_NOT_FOUND
                )
        else:
            appointment.agent = request.user
            
        appointment.save()
        
        # Notify citizen
        from apps.notifications.models import Notification
        Notification.objects.create(
            user=appointment.citizen,
            title="Rendez-vous programmé",
            message=f"Votre rendez-vous pour le dossier {appointment.dossier.reference} a été programmé au {appointment.scheduled_date.strftime('%d/%m/%Y %H:%M')}.",
            type='info'
        )
        
        # Notify agent if assigned by someone else
        if appointment.agent != request.user:
            Notification.objects.create(
                user=appointment.agent,
                title="Nouveau rendez-vous assigné",
                message=f"Un superviseur vous a assigné un rendez-vous pour le dossier {appointment.dossier.reference} le {appointment.scheduled_date.strftime('%d/%m/%Y %H:%M')}.",
                type='info'
            )
        
        return success_response(
            data=AppointmentSerializer(appointment).data,
            message='Rendez-vous programmé avec succès.'
        )

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsAgent | IsVerificationAgent | IsApprovalAgent | IsReceptionAgent | IsCivilAdmin | IsSuperAdmin])
    def cancel(self, request, pk=None):
        from apps.appointments.serializers import AppointmentCancelSerializer
        appointment = self.get_object()
        serializer = AppointmentCancelSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        if appointment.status in [Appointment.Status.COMPLETED, Appointment.Status.CANCELLED]:
            return error_response(
                message='Ce rendez-vous est déjà terminé ou annulé.',
                status_code=status.HTTP_400_BAD_REQUEST
            )
            
        appointment.status = Appointment.Status.CANCELLED
        appointment.agent = request.user
        
        cancel_reason = serializer.validated_data.get('cancel_reason', '')
        if cancel_reason:
            appointment.reason = f"{appointment.reason} | Annulé: {cancel_reason}"
            
        appointment.save()
        
        # Notify citizen
        from apps.notifications.models import Notification
        Notification.objects.create(
            user=appointment.citizen,
            title="Rendez-vous annulé",
            message=f"Votre rendez-vous pour le dossier {appointment.dossier.reference} a été annulé par la mairie." + (f" Motif: {cancel_reason}" if cancel_reason else ""),
            type='warning'
        )
        
        return success_response(
            data=AppointmentSerializer(appointment).data,
            message='Rendez-vous annulé avec succès.'
        )
