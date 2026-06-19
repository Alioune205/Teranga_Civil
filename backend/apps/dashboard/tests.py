import csv
from io import StringIO
from datetime import timedelta
from django.utils import timezone

from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.communes.models import Commune
from apps.dossiers.models import Dossier

User = get_user_model()


class DashboardTests(APITestCase):

    def setUp(self):
        self.commune_dakar = Commune.objects.create(name="Dakar", code="DK01")
        self.admin = User.objects.create_user(
            email="admin@test.com", password="password123",
            role="civil_admin", first_name="Moussa", last_name="Diallo",
            commune=self.commune_dakar
        )
        self.supervisor = User.objects.create_user(
            email="super@test.com", password="password123",
            role="civil_admin_supervisor", first_name="Super", last_name="Visor",
            commune=self.commune_dakar
        )
        self.citizen = User.objects.create_user(
            email="citoyen@test.com", password="password123",
            role="citizen", first_name="Jean", last_name="Dupont"
        )

        now = timezone.now()

        # Dossier approuvé (Commune Dakar, Agent Moussa Diallo, Type Birth)
        self.dossier_1 = Dossier.objects.create(
            citizen=self.citizen,
            commune=self.commune_dakar,
            assigned_agent=self.admin,
            status=Dossier.Status.APPROVED,
            type=Dossier.Type.BIRTH_CERTIFICATE,
            submitted_at=now - timedelta(days=2),
            completed_at=now
        )
        
        # Dossier rejeté (Type Marriage)
        self.dossier_2 = Dossier.objects.create(
            citizen=self.citizen,
            commune=self.commune_dakar,
            assigned_agent=self.admin,
            status=Dossier.Status.REJECTED,
            type=Dossier.Type.MARRIAGE_CERTIFICATE,
            submitted_at=now - timedelta(days=1),
            completed_at=now
        )

    def test_dashboard_stats(self):
        """Vérifie l'enrichissement du dashboard (KPIs 1 à 5)."""
        self.client.force_authenticate(user=self.admin)
        url = reverse('dashboard-stats')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data['data']
        
        # KPI 1 : Dossiers par type
        self.assertIn('dossiers_by_type', data)
        self.assertEqual(data['dossiers_by_type']['birth_certificate'], 1)
        self.assertEqual(data['dossiers_by_type']['marriage_certificate'], 1)
        
        # KPI 2 : Dossiers par commune (Top 5)
        self.assertIn('dossiers_by_commune', data)
        self.assertEqual(data['dossiers_by_commune'][0]['commune'], "Dakar")
        self.assertEqual(data['dossiers_by_commune'][0]['count'], 2)
        
        # KPI 3 : Agents les plus actifs
        self.assertIn('top_agents', data)
        self.assertEqual(data['top_agents'][0]['agent'], "Moussa Diallo")
        self.assertEqual(data['top_agents'][0]['dossiers_traites'], 2)
        
        # KPI 4 : Taux d'approbation
        self.assertIn('taux_approbation', data)
        self.assertEqual(data['taux_approbation'], 50.0) # 1 approuvé sur 2

    def test_export_csv_auth(self):
        """Vérifie que l'export n'est accessible qu'aux admins."""
        url = reverse('export-csv')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
        self.client.force_authenticate(user=self.citizen)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_export_csv_content(self):
        """Vérifie la génération et le contenu du CSV."""
        self.client.force_authenticate(user=self.supervisor)
        url = reverse('export-csv')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # La vue retourne 'text/csv; charset=utf-8' — on vérifie le type MIME seulement
        self.assertIn('text/csv', response['Content-Type'])
        
        # La vue utilise StreamingHttpResponse — il faut consommer streaming_content
        content = b''.join(response.streaming_content).decode('utf-8')
        reader = csv.DictReader(StringIO(content))
        rows = list(reader)
        
        self.assertEqual(len(rows), 2)
        self.assertIn('reference', rows[0])
        self.assertIn('citoyen', rows[0])
        self.assertEqual(rows[0]['commune'], 'Dakar')
        self.assertEqual(rows[0]['citoyen'], 'Jean Dupont')

    def test_export_csv_filtering(self):
        """Vérifie le filtrage par date_debut et date_fin."""
        self.client.force_authenticate(user=self.supervisor)
        
        today = timezone.now().strftime('%Y-%m-%d')
        url = reverse('export-csv') + f"?date_debut={today}&date_fin={today}"
        
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # StreamingHttpResponse — consommer streaming_content
        content = b''.join(response.streaming_content).decode('utf-8')
        reader = csv.DictReader(StringIO(content))
        rows = list(reader)
        
        # Aucun dossier n'a été soumis aujourd'hui (soumis à now-2j et now-1j)
        self.assertEqual(len(rows), 0)
