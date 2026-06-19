import unittest
from unittest.mock import patch, MagicMock

from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.notifications.models import Notification, DeviceToken
from apps.notifications.services import send_notification_async

User = get_user_model()


class NotificationTests(APITestCase):

    def setUp(self):
        self.admin = User.objects.create_user(
            email="admin@test.com", password="password123", first_name="Admin", last_name="A",
            role="civil_admin"
        )
        self.citizen = User.objects.create_user(
            email="citizen@test.com", password="password123", first_name="Citizen", last_name="C",
            role="citizen"
        )
        self.other_citizen = User.objects.create_user(
            email="other@test.com", password="password123", first_name="Other", last_name="O",
            role="citizen"
        )

        self.notif1 = Notification.objects.create(
            user=self.citizen,
            title="Dossier validé",
            message="Votre dossier est approuvé",
            is_read=False
        )
        
        self.notif_other = Notification.objects.create(
            user=self.other_citizen,
            title="Dossier en cours",
            message="En cours",
            is_read=False
        )

    def test_list_notifications_citizen(self):
        """Un citoyen ne doit voir que ses propres notifications, triées par date (pagination)."""
        self.client.force_authenticate(user=self.citizen)
        url = reverse('notification-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('count', response.data['data'])
        self.assertIn('results', response.data['data'])
        self.assertEqual(response.data['data']['count'], 1)
        self.assertEqual(response.data['data']['results'][0]['title'], "Dossier validé")

    def test_mark_as_read(self):
        """Marquer une notification comme lue."""
        self.client.force_authenticate(user=self.citizen)
        url = reverse('notification-mark-read', args=[self.notif1.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.notif1.refresh_from_db()
        self.assertTrue(self.notif1.is_read)

    def test_mark_other_notification_read_forbidden(self):
        """Un utilisateur ne peut pas modifier la notification d'un autre (sauf admin)."""
        self.client.force_authenticate(user=self.citizen)
        url = reverse('notification-mark-read', args=[self.notif_other.id])
        response = self.client.post(url)
        # Should return 404 because get_queryset filters out other's notifications
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    @patch('apps.notifications.services.threading.Thread')
    def test_send_notification_async(self, mock_thread):
        """Teste l'envoi asynchrone pour s'assurer que le thread est lancé."""
        mock_thread_instance = MagicMock()
        mock_thread.return_value = mock_thread_instance
        
        send_notification_async(
            token="test-token",
            title="Titre test",
            body="Body test"
        )
        
        mock_thread.assert_called_once()
        mock_thread_instance.start.assert_called_once()
