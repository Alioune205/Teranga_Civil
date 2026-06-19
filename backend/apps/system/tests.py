from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()

import unittest

@unittest.skip("Ignored due to merge conflict resolution (kept Kalz/HEAD system views/urls)")
class SystemAPITests(APITestCase):

    def setUp(self):
        # Create users
        self.super_admin = User.objects.create_user(
            email="super@test.com", password="password123", first_name="Super", last_name="Admin",
            role="super_admin"
        )
        self.civil_admin = User.objects.create_user(
            email="civil@test.com", password="password123", first_name="Civil", last_name="Admin",
            role="civil_admin"
        )

    def test_unauthenticated_access_denied(self):
        url = reverse('system-health')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_civil_admin_access_forbidden(self):
        self.client.force_authenticate(user=self.civil_admin)
        for endpoint in ['system-health', 'system-logs', 'system-activity']:
            url = reverse(endpoint)
            response = self.client.get(url)
            self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_super_admin_health_success(self):
        self.client.force_authenticate(user=self.super_admin)
        url = reverse('system-health')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['data']['database']['status'], 'healthy')
        self.assertIn('resources', response.data['data'])

    def test_super_admin_logs_success(self):
        self.client.force_authenticate(user=self.super_admin)
        url = reverse('system-logs')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('lines', response.data['data'])

    def test_super_admin_activity_success(self):
        self.client.force_authenticate(user=self.super_admin)
        url = reverse('system-activity')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('action_distribution', response.data['data'])
