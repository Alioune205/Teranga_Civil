import logging
from apps.appointments.models import Appointment
from apps.notifications.models import Notification

logger = logging.getLogger(__name__)

class AppointmentService:
    @staticmethod
    def create_appointment_for_rejection(dossier):
        """
        Création fail-safe d'un rendez-vous suite au rejet d'un dossier.
        """
        try:
            # Création du RDV
            appointment = Appointment.objects.create(
                dossier=dossier,
                citizen=dossier.citizen,
                reason=dossier.rejection_reason,
                status=Appointment.Status.PENDING
            )
            
            # Notification au citoyen
            Notification.objects.create(
                user=dossier.citizen,
                title="Présence requise à la mairie",
                message=f"Votre dossier {dossier.reference} nécessite votre présence physique. Un rendez-vous est en attente de programmation.",
                type='warning'
            )
            
            return appointment
        except Exception as e:
            logger.error(f"Erreur lors de la création du RDV pour le dossier {dossier.reference}: {e}")
            return None
