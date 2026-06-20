"""
Views for JWT authentication: login, register, refresh, logout.
"""
from rest_framework import status
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from drf_spectacular.utils import extend_schema, OpenApiResponse

from apps.shared.responses import success_response, error_response, created_response

from .serializers import (
    CustomTokenObtainPairSerializer,
    RegisterSerializer,
    LogoutSerializer,
)
from rest_framework.throttling import ScopedRateThrottle


class LoginView(TokenObtainPairView):
    """
    POST /api/auth/login/

    Authenticate a user and return JWT access + refresh tokens.
    """
    serializer_class = CustomTokenObtainPairSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'login'

    @extend_schema(
        tags=['Auth'],
        summary='Connexion utilisateur',
        description='Authentifie un utilisateur et retourne les tokens JWT.',
        responses={
            200: OpenApiResponse(description='Connexion réussie'),
            401: OpenApiResponse(description='Identifiants invalides'),
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception:
            return error_response(
                message='Email ou mot de passe incorrect.',
                status_code=status.HTTP_401_UNAUTHORIZED,
            )

        return success_response(
            data=serializer.validated_data,
            message='Connexion réussie.',
        )


class RegisterView(GenericAPIView):
    """
    POST /api/auth/register/

    Register a new citizen user.
    """
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    @extend_schema(
        tags=['Auth'],
        summary='Inscription citoyen',
        description='Crée un nouveau compte citoyen et déclenche l\'envoi d\'un OTP.',
        responses={
            201: OpenApiResponse(description='Inscription réussie, OTP envoyé'),
            400: OpenApiResponse(description='Données invalides'),
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Determine identifier (email or phone)
        identifier = user.email if user.email else user.phone

        # Trigger OTP send
        import random
        from django.utils import timezone
        from datetime import timedelta
        from apps.users.models import OTPCode
        
        code = str(random.randint(100000, 999999))
        expires_at = timezone.now() + timedelta(minutes=10)

        OTPCode.objects.create(identifier=identifier, code=code, expires_at=expires_at)
        
        if '@' in identifier:
            try:
                from apps.services.communication import SendGridEmailService
                email_service = SendGridEmailService()
                html_content = f"<h3>Code de vérification — TERANGA CIVIL</h3><p>Votre code de vérification OTP est : <strong>{code}</strong>.</p><p>Il expire dans 10 minutes.</p>"
                email_service.send_email(to_email=identifier, subject="Code de vérification — TERANGA CIVIL", html_content=html_content)
            except Exception as e:
                # Log but do not fail registration
                pass
        else:
            try:
                from apps.services.communication import TwilioSMSService
                sms_service = TwilioSMSService()
                sms_service.send_sms(to_phone=identifier, message=f"TERANGA CIVIL: Votre code de vérification OTP est {code}. Valide 10 minutes.")
            except Exception as e:
                pass

        return created_response(
            data={
                'needs_otp': True,
                'identifier': identifier,
            },
            message='Inscription réussie. Veuillez vérifier votre compte avec le code OTP.',
        )


class CustomTokenRefreshView(TokenRefreshView):
    """
    POST /api/auth/refresh/

    Refresh an access token using a valid refresh token.
    """
    permission_classes = [AllowAny]

    @extend_schema(
        tags=['Auth'],
        summary='Rafraîchir le token',
        description='Génère un nouveau token d\'accès à partir du refresh token.',
        responses={
            200: OpenApiResponse(description='Token rafraîchi'),
            401: OpenApiResponse(description='Refresh token invalide'),
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception:
            return error_response(
                message='Token de rafraîchissement invalide ou expiré.',
                status_code=status.HTTP_401_UNAUTHORIZED,
            )

        return success_response(
            data=serializer.validated_data,
            message='Token rafraîchi avec succès.',
        )


class LogoutView(GenericAPIView):
    """
    POST /api/auth/logout/

    Blacklist the refresh token to log the user out.
    """
    serializer_class = LogoutSerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Auth'],
        summary='Déconnexion',
        description='Invalide le refresh token pour déconnecter l\'utilisateur.',
        responses={
            200: OpenApiResponse(description='Déconnexion réussie'),
            400: OpenApiResponse(description='Token invalide'),
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            token = RefreshToken(serializer.validated_data['refresh'])
            token.blacklist()
        except TokenError:
            return error_response(
                message='Token invalide ou déjà révoqué.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        return success_response(message='Déconnexion réussie.')


import random
from django.utils import timezone
from datetime import timedelta
from django.db.models import Q
from apps.users.models import OTPCode, User
from .serializers import SendOTPSerializer, VerifyOTPSerializer
from rest_framework.throttling import ScopedRateThrottle

class SendOTPView(GenericAPIView):
    """
    POST /api/auth/otp/send/
    """
    serializer_class = SendOTPSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'otp'

    @extend_schema(
        tags=['Auth'],
        summary='Demander un code OTP',
        responses={200: OpenApiResponse(description='Code OTP envoyé')},
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.validated_data['identifier']

        code = str(random.randint(100000, 999999))
        expires_at = timezone.now() + timedelta(minutes=10)

        OTPCode.objects.create(identifier=identifier, code=code, expires_at=expires_at)
        
        if '@' in identifier:
            from apps.services.communication import SendGridEmailService
            email_service = SendGridEmailService()
            html_content = f"<h3>Code de vérification — TERANGA CIVIL</h3><p>Votre code de vérification OTP est : <strong>{code}</strong>.</p><p>Il expire dans 10 minutes.</p>"
            email_service.send_email(to_email=identifier, subject="Code de vérification — TERANGA CIVIL", html_content=html_content)
        else:
            from apps.services.communication import TwilioSMSService
            sms_service = TwilioSMSService()
            sms_service.send_sms(to_phone=identifier, message=f"TERANGA CIVIL: Votre code de vérification OTP est {code}. Valide 10 minutes.")

        return success_response(message='Code OTP envoyé avec succès.')


class VerifyOTPView(GenericAPIView):
    """
    POST /api/auth/otp/verify/
    """
    serializer_class = VerifyOTPSerializer
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'login'

    @extend_schema(
        tags=['Auth'],
        summary='Vérifier un code OTP',
        responses={200: OpenApiResponse(description='Connexion réussie')},
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        otp = serializer.validated_data['otp']
        identifier = serializer.validated_data['identifier']
        
        otp.is_used = True
        otp.save()
        
        user = User.objects.filter(Q(email=identifier) | Q(phone=identifier)).first()
        if user:
            if not user.is_verified:
                user.is_verified = True
                user.save()
            
            # Log history
            ip_address = request.META.get('REMOTE_ADDR')
            user_agent = request.META.get('HTTP_USER_AGENT')
            from apps.users.models import LoginHistory
            LoginHistory.objects.create(
                user=user,
                ip_address=ip_address,
                user_agent=user_agent
            )

            refresh = RefreshToken.for_user(user)
            
            return success_response(
                data={
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                    'user': {
                        'id': str(user.id),
                        'email': user.email,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                        'full_name': user.full_name,
                        'role': user.role,
                        'is_verified': user.is_verified,
                    },
                },
                message='Code OTP vérifié et connexion réussie.',
            )

        return error_response(message='Utilisateur introuvable.', status_code=status.HTTP_404_NOT_FOUND)


from .serializers import LoginHistorySerializer
from apps.users.models import LoginHistory

class LoginHistoryView(GenericAPIView):
    """
    GET /api/auth/login-history/
    """
    serializer_class = LoginHistorySerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Auth'],
        summary='Historique des connexions',
        responses={200: LoginHistorySerializer(many=True)},
    )
    def get(self, request, *args, **kwargs):
        history = LoginHistory.objects.filter(user=request.user)[:50]
        serializer = self.get_serializer(history, many=True)
        return success_response(data=serializer.data, message='Historique récupéré.')

import hashlib
import secrets
import uuid
import jwt
from django.conf import settings
from django.core.mail import send_mail
from django.core.cache import cache
from datetime import timedelta
from apps.authentication.models import OTPToken
from apps.audit_logs.models import AuditLog
from .serializers import (
    SuperAdminOTPRequestSerializer,
    SuperAdminOTPVerifySerializer,
    SuperAdminPasswordResetSerializer
)

def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

class SuperAdminOTPRequestView(GenericAPIView):
    """
    POST /api/v1/auth/super-admin/otp-request
    """
    serializer_class = SuperAdminOTPRequestSerializer
    permission_classes = [AllowAny]

    @extend_schema(
        tags=['Auth Super Admin'],
        summary='Demander un OTP Super Admin',
        description='Génère un code OTP pour un compte super administrateur et l\'envoie par e-mail.'
    )
    def post(self, request, *args, **kwargs):
        ip = get_client_ip(request)
        request_key = f"super_admin_otp_request_{ip}"
        request_count = cache.get(request_key, 0)
        
        if request_count >= 3:
            return error_response(
                message="Limite de demandes OTP dépassée. Réessayez plus tard (max 3/heure).",
                status_code=status.HTTP_429_TOO_MANY_REQUESTS
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']

        # Générer l'OTP et le sel
        otp = str(secrets.randbelow(900000) + 100000) # Assure 6 chiffres
        salt = secrets.token_hex(16)
        otp_hash = hashlib.sha256((otp + salt).encode('utf-8')).hexdigest()
        expires_at = timezone.now() + timedelta(minutes=10)

        # Enregistrer en base
        OTPToken.objects.create(
            email=email,
            otp_hash=otp_hash,
            salt=salt,
            expires_at=expires_at
        )

        # Envoyer l'email via SendGrid
        from apps.services.communication import SendGridEmailService
        email_service = SendGridEmailService()
        html_content = f"<h3>Code de validation — Teranga Civil Super Admin</h3><p>Votre code de vérification OTP est : <strong>{otp}</strong>.</p><p>Il expire dans 10 minutes.</p>"
        email_service.send_email(to_email=email, subject="Code de validation — Teranga Civil Super Admin", html_content=html_content)

        # Incrémenter le limiteur
        cache.set(request_key, request_count + 1, timeout=3600) # 1 heure

        return success_response(message="Un code OTP a été envoyé à votre adresse e-mail.")


class SuperAdminOTPVerifyView(GenericAPIView):
    """
    POST /api/v1/auth/super-admin/otp-verify
    """
    serializer_class = SuperAdminOTPVerifySerializer
    permission_classes = [AllowAny]

    @extend_schema(
        tags=['Auth Super Admin'],
        summary='Vérifier un OTP Super Admin',
        description='Vérifie le code OTP et renvoie un reset_token JWT unique valide 15 minutes.'
    )
    def post(self, request, *args, **kwargs):
        ip = get_client_ip(request)
        block_key = f"super_admin_otp_verify_blocked_{ip}"
        
        if cache.get(block_key):
            return error_response(
                message="Trop de tentatives de vérification. Accès bloqué pour 30 minutes.",
                status_code=status.HTTP_429_TOO_MANY_REQUESTS
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        code = serializer.validated_data['code']

        attempts_key = f"super_admin_otp_verify_attempts_{ip}"
        attempts = cache.get(attempts_key, 0)

        # Récupérer le dernier OTP valide pour cet email
        otp_token = OTPToken.objects.filter(email=email, is_used=False, expires_at__gte=timezone.now()).order_by('-created_at').first()
        
        if not otp_token:
            attempts += 1
            cache.set(attempts_key, attempts, timeout=1800)
            if attempts >= 5:
                cache.set(block_key, True, timeout=1800)
            return error_response(message="Code OTP invalide ou expiré.", status_code=status.HTTP_400_BAD_REQUEST)

        # Vérifier le hash
        input_hash = hashlib.sha256((code + otp_token.salt).encode('utf-8')).hexdigest()
        if input_hash != otp_token.otp_hash:
            attempts += 1
            cache.set(attempts_key, attempts, timeout=1800)
            if attempts >= 5:
                cache.set(block_key, True, timeout=1800)
            return error_response(message="Code OTP invalide.", status_code=status.HTTP_400_BAD_REQUEST)

        # Valider et consommer l'OTP
        otp_token.is_used = True
        otp_token.save()

        # Réinitialiser les tentatives
        cache.delete(attempts_key)
        cache.delete(block_key)

        # Générer le token de réinitialisation JWT à usage unique
        jti = uuid.uuid4().hex
        cache.set(f"reset_token_active_{jti}", email, timeout=900) # Valide 15 minutes
        
        payload = {
            'email': email,
            'jti': jti,
            'purpose': 'super_admin_password_reset',
            'exp': timezone.now() + timedelta(minutes=15)
        }
        reset_token = jwt.encode(payload, settings.SECRET_KEY, algorithm='HS256')

        return success_response(
            data={'reset_token': reset_token},
            message="Code OTP validé avec succès."
        )


class SuperAdminPasswordResetView(GenericAPIView):
    """
    POST /api/v1/auth/super-admin/reset-password
    """
    serializer_class = SuperAdminPasswordResetSerializer
    permission_classes = [AllowAny]

    @extend_schema(
        tags=['Auth Super Admin'],
        summary='Réinitialiser le mot de passe Super Admin',
        description='Réinitialise le mot de passe du super administrateur en utilisant un reset_token valide.'
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        reset_token = serializer.validated_data['reset_token']
        new_password = serializer.validated_data['new_password']

        # Décoder le JWT
        try:
            payload = jwt.decode(reset_token, settings.SECRET_KEY, algorithms=['HS256'])
        except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
            return error_response(message="Jeton de réinitialisation invalide ou expiré.", status_code=status.HTTP_400_BAD_REQUEST)

        email = payload.get('email')
        jti = payload.get('jti')
        purpose = payload.get('purpose')

        if purpose != 'super_admin_password_reset':
            return error_response(message="Objectif de jeton invalide.", status_code=status.HTTP_400_BAD_REQUEST)

        # Vérifier si le jeton est actif dans le cache (usage unique)
        active_email = cache.get(f"reset_token_active_{jti}")
        if not active_email or active_email != email:
            return error_response(message="Ce jeton a déjà été utilisé ou a expiré.", status_code=status.HTTP_400_BAD_REQUEST)

        # Modifier le mot de passe
        user = User.objects.filter(email=email).first()
        if not user or user.role != 'super_admin':
            return error_response(message="Compte super administrateur introuvable.", status_code=status.HTTP_404_NOT_FOUND)

        user.set_password(new_password)
        user.save()

        # Invalider le reset_token
        cache.delete(f"reset_token_active_{jti}")

        # Invalider toutes les sessions actives (JWT blacklist simplejwt)
        from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
        outstanding_tokens = OutstandingToken.objects.filter(user=user)
        for t in outstanding_tokens:
            BlacklistedToken.objects.get_or_create(token=t)

        # Loguer l'action d'audit
        AuditLog.log(
            user=user,
            action=AuditLog.Action.UPDATE,
            resource_type='user',
            resource_id=user.id,
            details={'action': 'super_admin_password_reset'},
            ip_address=get_client_ip(request)
        )

        return success_response(message="Votre mot de passe a été réinitialisé avec succès et toutes les sessions actives ont été déconnectées.")


class ChangePasswordView(GenericAPIView):
    """
    POST /api/auth/change-password/
    
    Allow an authenticated user to change their password or PIN.
    """
    serializer_class = __import__('apps.authentication.serializers', fromlist=['ChangePasswordSerializer']).ChangePasswordSerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Auth'],
        summary='Changer le mot de passe / PIN',
        description='Modifie le mot de passe de l\'utilisateur connecté.',
        responses={
            200: OpenApiResponse(description='Mot de passe modifié avec succès.'),
            400: OpenApiResponse(description='Ancien mot de passe incorrect ou données invalides.'),
        },
    )
    def post(self, request, *args, **kwargs):
        user = request.user
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        old_password = serializer.validated_data['old_password']
        new_password = serializer.validated_data['new_password']

        if not user.check_password(old_password):
            return error_response(
                message='L\'ancien mot de passe est incorrect.',
                status_code=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.save()

        # Optionally log the action
        ip_address = request.META.get('REMOTE_ADDR')
        AuditLog = __import__('apps.audit_logs.models', fromlist=['AuditLog']).AuditLog
        try:
            AuditLog.log(
                user=user,
                action=AuditLog.Action.UPDATE,
                resource_type='user',
                resource_id=user.id,
                details={'action': 'change_password'},
                ip_address=ip_address
            )
        except Exception:
            pass

        return success_response(message='Mot de passe modifié avec succès.')

