import logging
from typing import Dict, Any, Optional
from django.conf import settings
from twilio.rest import Client as TwilioClient
from twilio.base.exceptions import TwilioRestException
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content

logger = logging.getLogger('system')

class TwilioSMSService:
    """
    Intégration réelle de l'API Twilio pour l'envoi de SMS (OTP, Alertes urgentes).
    Remplace les anciens logs Mock Fallback.
    """
    
    def __init__(self):
        self.account_sid = settings.TWILIO_ACCOUNT_SID
        self.auth_token = settings.TWILIO_AUTH_TOKEN
        self.phone_number = settings.TWILIO_PHONE_NUMBER
        
        # Initialize only if credentials are provided
        if self.account_sid and self.auth_token:
            self.client = TwilioClient(self.account_sid, self.auth_token)
        else:
            self.client = None
            logger.warning("TwilioSMSService: Credentials missing, SMS will not be sent.")

    def send_sms(self, to_phone: str, message: str) -> bool:
        """
        Envoie un SMS à un numéro spécifique.
        """
        if not self.client:
            logger.error(f"Twilio: Cannot send SMS to {to_phone}, client not initialized.")
            return False
            
        try:
            response = self.client.messages.create(
                body=message,
                from_=self.phone_number,
                to=to_phone
            )
            logger.info(f"Twilio: SMS successfully sent to {to_phone}. SID: {response.sid}")
            return True
        except TwilioRestException as e:
            logger.error(f"Twilio API Error sending SMS to {to_phone}: {e}")
            return False
        except Exception as e:
            logger.error(f"Twilio Unexpected Error: {str(e)}", exc_info=True)
            return False


class SendGridEmailService:
    """
    Intégration réelle de l'API SendGrid pour l'envoi d'emails transactionnels.
    Remplace les anciens logs Mock Fallback.
    """
    
    def __init__(self):
        self.api_key = settings.SENDGRID_API_KEY
        self.from_email = settings.SENDGRID_FROM_EMAIL
        
        if self.api_key:
            self.client = SendGridAPIClient(self.api_key)
        else:
            self.client = None
            logger.warning("SendGridEmailService: API Key missing, Emails will not be sent.")

    def send_email(self, to_email: str, subject: str, html_content: str) -> bool:
        """
        Envoie un email transactionnel (OTP, notification de dossier, etc.)
        """
        if not self.client:
            logger.error(f"SendGrid: Cannot send Email to {to_email}, client not initialized.")
            return False
            
        message = Mail(
            from_email=Email(self.from_email),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content("text/html", html_content)
        )
        
        try:
            response = self.client.send(message)
            if response.status_code in [200, 201, 202]:
                logger.info(f"SendGrid: Email successfully sent to {to_email}. Status: {response.status_code}")
                return True
            else:
                logger.warning(f"SendGrid: Email sent but received status code {response.status_code}")
                return False
        except Exception as e:
            logger.error(f"SendGrid Error sending email to {to_email}: {str(e)}", exc_info=True)
            return False
