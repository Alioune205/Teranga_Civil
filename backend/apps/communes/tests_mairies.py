from django.test import TestCase, override_settings
from django.urls import reverse
from unittest.mock import patch
from rest_framework.test import APIClient
from rest_framework import status
from apps.users.models import User
from .models import Commune, Mairie

class MairiesProchesTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.commune = Commune.objects.create(
            name="Dakar Plateau", region="Dakar", department="Dakar", code="DKR01"
        )
        self.user = User.objects.create_user(
            email="test@teranga.sn",
            first_name="Test",
            last_name="User",
            password="password123",
            commune=self.commune
        )
        self.mairie = Mairie.objects.create(
            nom="Mairie de Dakar Plateau",
            commune=self.commune,
            latitude="14.693425",
            longitude="-17.447938"
        )

    def test_non_authentifie_retourne_401(self):
        url = reverse('mairies-proches')
        response = self.client.get(url, {'lat': '14.693', 'lng': '-17.447'})
        self.assertEqual(response.status_code, 401)

    def test_mairies_filtrees_par_commune(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('mairies-proches')
        response = self.client.get(url, {'lat': '14.693', 'lng': '-17.447'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['data']['mairies']), 1)
        self.assertEqual(response.data['data']['mairies'][0]['commune_nom'], self.commune.name)

    def test_tri_par_distance_croissante(self):
        self.client.force_authenticate(user=self.user)
        Mairie.objects.create(
            nom="Mairie Lointaine",
            commune=self.commune,
            latitude="14.8000",
            longitude="-17.4000"
        )
        url = reverse('mairies-proches')
        response = self.client.get(url, {'lat': '14.693', 'lng': '-17.447'})
        distances = [m['distance_km'] for m in response.data['data']['mairies']]
        self.assertEqual(distances, sorted(distances))

    def test_coordonnees_manquantes_retourne_400(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get(reverse('mairies-proches'))
        self.assertEqual(response.status_code, 400)

    def test_coordonnees_invalides_retourne_400(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('mairies-proches')
        response = self.client.get(url, {'lat': 'abc', 'lng': 'xyz'})
        self.assertEqual(response.status_code, 400)


class ItineraireTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.commune = Commune.objects.create(
            name="Dakar Plateau", region="Dakar", department="Dakar", code="DKR01"
        )
        self.user = User.objects.create_user(
            email="test@teranga.sn",
            first_name="Test",
            last_name="User",
            password="password123",
            commune=self.commune
        )
        self.mairie = Mairie.objects.create(
            nom="Mairie de Dakar Plateau",
            commune=self.commune,
            latitude="14.693425",
            longitude="-17.447938"
        )

    @override_settings(GOOGLE_MAPS_API_KEY='dummy')
    @patch('apps.communes.services.requests.get')
    def test_itineraire_retourne_polyline(self, mock_get):
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {
            "status": "OK",
            "routes": [{
                "overview_polyline": {"points": "encoded_string"},
                "legs": [{
                    "distance": {"text": "3,2 km", "value": 3200},
                    "duration": {"text": "12 mins", "value": 720},
                    "steps": []
                }],
                "bounds": {}
            }]
        }
        self.client.force_authenticate(user=self.user)
        url = reverse('mairie-itineraire', kwargs={'pk': self.mairie.pk})
        response = self.client.get(url, {'lat': '14.693', 'lng': '-17.447'})
        self.assertEqual(response.status_code, 200)
        self.assertIn('polyline', response.data['data']['itineraire'])
        self.assertNotIn('key', str(response.data))
        self.assertNotIn('GOOGLE_MAPS_API_KEY', str(response.data))

    def test_mairie_inexistante_retourne_404(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('mairie-itineraire', kwargs={'pk': 9999})
        response = self.client.get(url, {'lat': '14.693', 'lng': '-17.447'})
        self.assertEqual(response.status_code, 404)

    def test_mode_invalide_retourne_400(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('mairie-itineraire', kwargs={'pk': self.mairie.pk})
        response = self.client.get(url, {'lat': '14.693', 'lng': '-17.447', 'mode': 'rocket'})
        self.assertEqual(response.status_code, 400)
