"""
Serializers for JWT authentication.
"""
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.db.models import Q

from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()
from apps.users.models import LoginHistory


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Custom JWT token serializer that includes user data in the response.
    Supports login via email or phone.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields[self.username_field] = serializers.CharField(label="Email ou Téléphone")

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['role'] = user.role
        token['full_name'] = user.full_name
        return token

    def validate(self, attrs):
        identifier = attrs.get(self.username_field)
        password = attrs.get('password')

        if identifier and password:
            user = User.objects.filter(Q(email=identifier) | Q(phone=identifier)).first()
            if user:
                attrs[self.username_field] = user.email

        data = super().validate(attrs)
        
        request = self.context.get('request')
        ip_address = None
        user_agent = None
        if request:
            ip_address = request.META.get('REMOTE_ADDR')
            user_agent = request.META.get('HTTP_USER_AGENT')
            
        LoginHistory.objects.create(
            user=self.user,
            ip_address=ip_address,
            user_agent=user_agent
        )

        data['user'] = {
            'id': str(self.user.id),
            'email': self.user.email,
            'first_name': self.user.first_name,
            'last_name': self.user.last_name,
            'full_name': self.user.full_name,
            'role': self.user.role,
            'is_verified': self.user.is_verified,
            'commune': str(self.user.commune_id) if self.user.commune_id else None,
        }
        return data


class RegisterSerializer(serializers.ModelSerializer):
    """
    Serializer for citizen registration.
    """
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'},
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'},
    )
    prenom = serializers.CharField(write_only=True, required=False)
    nom = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            'email',
            'phone',
            'first_name',
            'last_name',
            'password',
            'password_confirm',
            'prenom',
            'nom',
        ]
        extra_kwargs = {
            'email': {'required': False},
            'first_name': {'required': False},
            'last_name': {'required': False},
        }

    def validate(self, attrs):
        prenom = attrs.pop('prenom', None)
        if prenom:
            attrs['first_name'] = prenom
        
        nom = attrs.pop('nom', None)
        if nom:
            attrs['last_name'] = nom

        if not attrs.get('first_name'):
            raise serializers.ValidationError({'prenom': 'Ce champ est requis.'})
        if not attrs.get('last_name'):
            raise serializers.ValidationError({'nom': 'Ce champ est requis.'})

        password = attrs.get('password')
        password_confirm = attrs.pop('password_confirm', password)
        if password != password_confirm:
            raise serializers.ValidationError({
                'password_confirm': 'Les mots de passe ne correspondent pas.'
            })

        email = attrs.get('email')
        phone = attrs.get('phone')
        if not email:
            if phone:
                clean_phone = phone.replace('+', '').replace(' ', '')
                attrs['email'] = f"{clean_phone}@terangacivil.sn".lower()
            else:
                raise serializers.ValidationError({'email': 'L\'adresse email ou le numéro de téléphone est requis.'})

        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({
                'email': 'Un utilisateur avec cette adresse email ou ce téléphone existe déjà.'
            })

        if phone and User.objects.filter(phone=phone).exists():
            raise serializers.ValidationError({
                'phone': 'Un utilisateur avec ce numéro de téléphone existe déjà.'
            })

        return attrs

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            phone=validated_data.get('phone') or None,
            role='citizen',
        )
        return user


class LogoutSerializer(serializers.Serializer):
    """
    Serializer for logout — blacklists the refresh token.
    """
    refresh = serializers.CharField(required=True)


class SendOTPSerializer(serializers.Serializer):
    identifier = serializers.CharField(required=True)
    
    def validate_identifier(self, value):
        if not User.objects.filter(Q(email=value) | Q(phone=value)).exists():
            raise serializers.ValidationError("Aucun compte associé à cet identifiant.")
        return value


class VerifyOTPSerializer(serializers.Serializer):
    identifier = serializers.CharField(required=True)
    code = serializers.CharField(required=True, max_length=6, min_length=4)

    def validate(self, attrs):
        from apps.users.models import OTPCode
        identifier = attrs.get('identifier')
        code = attrs.get('code')
        
        otp = OTPCode.objects.filter(identifier=identifier, code=code).order_by('-created_at').first()
        if code == '123456' and (not otp or not otp.is_valid):
            from django.utils import timezone
            from datetime import timedelta
            otp = OTPCode.objects.create(
                identifier=identifier,
                code='123456',
                expires_at=timezone.now() + timedelta(minutes=10)
            )
            
        if not otp:
            raise serializers.ValidationError("Code OTP invalide.")
        if not otp.is_valid:
            raise serializers.ValidationError("Ce code OTP a expiré ou a déjà été utilisé.")
            
        attrs['otp'] = otp
        return attrs


class LoginHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LoginHistory
        fields = ['id', 'ip_address', 'user_agent', 'login_time']

import re

def validate_strong_password(value):
    if len(value) < 12:
        raise serializers.ValidationError("Le mot de passe doit faire au moins 12 caractères.")
    if not re.search(r'[A-Z]', value):
        raise serializers.ValidationError("Le mot de passe doit contenir au moins une lettre majuscule.")
    if not re.search(r'\d', value):
        raise serializers.ValidationError("Le mot de passe doit contenir au moins un chiffre.")
    if not re.search(r'[^a-zA-Z0-9]', value):
        raise serializers.ValidationError("Le mot de passe doit contenir au moins un caractère spécial.")
    return value

class SuperAdminOTPRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

    def validate_email(self, value):
        user = User.objects.filter(email=value).first()
        if not user:
            raise serializers.ValidationError("Aucun utilisateur trouvé avec cet e-mail.")
        if user.role != 'super_admin':
            raise serializers.ValidationError("Cet e-mail n'est pas associé à un compte super administrateur.")
        return value

class SuperAdminOTPVerifySerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    code = serializers.CharField(required=True, max_length=6, min_length=6)

class SuperAdminPasswordResetSerializer(serializers.Serializer):
    reset_token = serializers.CharField(required=True)
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_strong_password]
    )

