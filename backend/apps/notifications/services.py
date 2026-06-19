import logging
from typing import Dict, Optional
from firebase_admin import messaging
from firebase_admin.exceptions import FirebaseError

from django.contrib.auth import get_user_model
from django.db import transaction
from .models import Notification, DeviceToken

logger = logging.getLogger('system')
User = get_user_model()


class FCMService:
    """
    Service d'envoi de notifications push via Firebase Cloud Messaging.
    Combine la création en base (Notification) et l'envoi réel (FCM).
    """

    @staticmethod
    def send_notification_to_user(
        user: User,
        title: str,
        body: str,
        notification_type=Notification.Type.INFO,
        data: Optional[Dict[str, str]] = None
    ) -> Optional[Notification]:
        """
        Crée une notification en base et envoie un push FCM.
        """
        try:
            # 1. Créer l'enregistrement en base
            with transaction.atomic():
                # Remap old TypeChoices to new Type if needed
                if hasattr(notification_type, 'value'):
                    notification_type = notification_type.value
                elif notification_type == 'success':
                    notification_type = Notification.Type.UPDATE
                elif notification_type == 'action_required':
                    notification_type = Notification.Type.WARNING
                
                # Check if it's a valid choice
                valid_choices = [c[0] for c in Notification.Type.choices]
                if notification_type not in valid_choices:
                    notification_type = Notification.Type.INFO

                notification = Notification.objects.create(
                    user=user,
                    title=title,
                    message=body,
                    notification_type=notification_type,
                    data=data or {},
                )

            # 2. Récupérer les tokens actifs
            tokens = list(
                DeviceToken.objects.filter(user=user).values_list('token', flat=True)
            )
            
            if not tokens:
                logger.info(f"Aucun token FCM trouvé pour l'utilisateur {user.id}")
                return notification

            # 3. Envoi push réel via firebase_admin de manière asynchrone
            def _send_batch():
                try:
                    messages = [
                        messaging.Message(
                            notification=messaging.Notification(title=title, body=body),
                            data=data or {},
                            token=token
                        ) for token in tokens
                    ]
                    response: messaging.BatchResponse = messaging.send_each(messages)
                    
                    logger.info(f"FCM Async: {response.success_count} notifications envoyées à {user.id}")
                    if response.failure_count > 0:
                        logger.warning(f"FCM Async: {response.failure_count} échecs pour l'utilisateur {user.id}")
                except FirebaseError as e:
                    logger.error(f"Erreur Firebase critique pour l'utilisateur {user.id}: {str(e)}", exc_info=True)
                except Exception as e:
                    logger.error(f"Erreur inattendue lors de l'envoi FCM (User: {user.id}): {str(e)}", exc_info=True)

            thread = threading.Thread(target=_send_batch, daemon=True)
            thread.start()

            return notification

        except Exception as e:
            logger.error(f"Erreur inattendue lors de la création de la notification (User: {user.id}): {str(e)}", exc_info=True)
            return None


def send_push_notification(user: User, title: str, body: str, data: Optional[Dict[str, str]] = None) -> None:
    """Rétrocompatibilité pour l'ancien code."""
    FCMService.send_notification_to_user(
        user=user,
        title=title,
        body=body,
        notification_type=Notification.Type.INFO,
        data=data
    )


import threading

def send_notification_async(token: str, title: str, body: str, data: Optional[Dict[str, str]] = None):
    """
    Envoi asynchrone d'une notification push via un thread dédié (daemon).
    Ne bloque pas la requête principale et gère ses propres exceptions.
    """
    def _send():
        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=token
            )
            response = messaging.send(message)
            logger.info(f"FCM Async: Notification envoyée au token {token[:10]}... (ID: {response})")
        except FirebaseError as e:
            logger.error(f"Erreur Firebase lors de l'envoi async au token {token[:10]}... : {str(e)}", exc_info=True)
        except Exception as e:
            logger.error(f"Erreur inattendue lors de l'envoi async : {str(e)}", exc_info=True)

    thread = threading.Thread(target=_send, daemon=True)
    thread.start()
