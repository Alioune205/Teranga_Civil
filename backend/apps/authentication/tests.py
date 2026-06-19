from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.users.models import User, OTPCode

class AuthenticationTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_register_creates_user_and_sends_otp(self):
        data = {
            "first_name": "Test",
            "last_name": "User",
            "email": "testuser@terangacivil.sn",
            "password": "StrongPassword123!",
            "password_confirm": "StrongPassword123!"
        }
        
        response = self.client.post('/api/v1/auth/register/', data, format='json')
        
        # In case the URL is /api/auth/register/
        if response.status_code == 404:
            response = self.client.post('/api/auth/register/', data, format='json')
            
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data.get('data', {}).get('needs_otp'))
        self.assertEqual(response.data.get('data', {}).get('identifier'), data['email'])
        
        # Verify user created
        user = User.objects.filter(email=data['email']).first()
        self.assertIsNotNone(user)
        self.assertFalse(user.is_verified)
        
        # Verify OTP created
        otp = OTPCode.objects.filter(identifier=data['email']).first()
        self.assertIsNotNone(otp)

    def test_verify_otp(self):
        # Create user
        user = User.objects.create_user(
            email='testverify@terangacivil.sn',
            password='StrongPassword123!',
            first_name='Test',
            last_name='Verify'
        )
        self.assertFalse(user.is_verified)
        
        # Create OTP
        from django.utils import timezone
        from datetime import timedelta
        otp = OTPCode.objects.create(
            identifier=user.email,
            code='123456',
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        
        data = {
            "identifier": user.email,
            "code": "123456"
        }
        
        response = self.client.post('/api/v1/auth/otp/verify/', data, format='json')
        if response.status_code == 404:
            response = self.client.post('/api/auth/otp/verify/', data, format='json')
            
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Check user is verified
        user.refresh_from_db()
        self.assertTrue(user.is_verified)
        
        # Check tokens returned
        self.assertIn('access', response.data.get('data', {}))
        self.assertIn('refresh', response.data.get('data', {}))

    def test_double_register_empty_phone(self):
        data1 = {
            "first_name": "Test1",
            "last_name": "User1",
            "email": "testuser1@terangacivil.sn",
            "password": "StrongPassword123!",
            "password_confirm": "StrongPassword123!",
            "phone": ""
        }
        
        response1 = self.client.post('/api/v1/auth/register/', data1, format='json')
        if response1.status_code == 404:
            response1 = self.client.post('/api/auth/register/', data1, format='json')
        self.assertEqual(response1.status_code, status.HTTP_201_CREATED)

        data2 = {
            "first_name": "Test2",
            "last_name": "User2",
            "email": "testuser2@terangacivil.sn",
            "password": "StrongPassword123!",
            "password_confirm": "StrongPassword123!",
            "phone": ""
        }
        
        response2 = self.client.post('/api/v1/auth/register/', data2, format='json')
        if response2.status_code == 404:
            response2 = self.client.post('/api/auth/register/', data2, format='json')
        self.assertEqual(response2.status_code, status.HTTP_201_CREATED)
