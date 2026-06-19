import os
import sys
import django

# Configuration de l'environnement Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.services.communication import TwilioSMSService, SendGridEmailService
from django.conf import settings

def main():
    print("===========================================")
    print("🚀 TEST RÉEL - API TWILIO & SENDGRID")
    print("===========================================\n")

    print(f"[INFO] Vérification des clés dans .env...")
    
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        print("❌ ATTENTION: Les clés Twilio (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN) sont manquantes dans votre .env!")
    else:
        print("✅ Clés Twilio détectées.")

    if not settings.SENDGRID_API_KEY:
        print("❌ ATTENTION: La clé SendGrid (SENDGRID_API_KEY) est manquante dans votre .env!")
    else:
        print("✅ Clé SendGrid détectée.")

    print("\nQue voulez-vous tester en conditions RÉELLES ?")
    print("1. Envoi de SMS (Twilio)")
    print("2. Envoi d'Email (SendGrid)")
    print("3. Les deux")
    print("4. Quitter")
    
    choix = input("\nVotre choix (1/2/3/4) : ")

    if choix in ['1', '3']:
        print("\n--- TEST SMS ---")
        phone = input("Entrez votre numéro de téléphone (format international, ex: +221771234567) : ")
        message = "Bonjour ! Ceci est un test RÉEL d'intégration SMS depuis l'API Teranga Civil (DEV 2B)."
        print(f"Tentative d'envoi du SMS vers {phone}...")
        
        sms_service = TwilioSMSService()
        success = sms_service.send_sms(to_phone=phone, message=message)
        
        if success:
            print("✅ SUCCÈS ! Le SMS a été envoyé à Twilio. Regardez votre téléphone !")
        else:
            print("❌ ÉCHEC. L'envoi du SMS a échoué. Vérifiez vos logs ou vos crédits Twilio.")

    if choix in ['2', '3']:
        print("\n--- TEST EMAIL ---")
        email = input("Entrez votre adresse email (ex: mon.adresse@gmail.com) : ")
        subject = "Test RÉEL SendGrid - Teranga Civil"
        html_content = "<h3>Félicitations !</h3><p>L'intégration de l'API SendGrid fonctionne parfaitement en conditions réelles.</p><p>Signé: Massogui (DEV 2B)</p>"
        
        print(f"Tentative d'envoi de l'email vers {email}...")
        
        email_service = SendGridEmailService()
        success = email_service.send_email(to_email=email, subject=subject, html_content=html_content)
        
        if success:
            print("✅ SUCCÈS ! L'email a été expédié. Vérifiez votre boîte de réception (ou vos Spams).")
        else:
            print("❌ ÉCHEC. L'envoi de l'email a échoué. Vérifiez votre clé API ou si l'expéditeur SendGrid est vérifié.")

    print("\nFin du test.")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nTest annulé.")
