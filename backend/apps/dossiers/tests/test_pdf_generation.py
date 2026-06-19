"""
Tests for PDF Generation of different dossier types (Pape's PDFs).
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.dossiers.services.pdf_generator import generate_signed_certificate

User = get_user_model()

class PDFGenerationTests(TestCase):
    def setUp(self):
        self.commune = Commune.objects.create(
            code="DKR-PLT",
            name="Plateau",
            department="Dakar",
            region="Dakar"
        )
        self.citizen = User.objects.create_user(
            email='citizen@example.com',
            password='password123',
            first_name='Alioune',
            last_name='Sene',
            role='citizen'
        )
        self.officier = User.objects.create_user(
            email='officier@example.com',
            password='password123',
            first_name='Pape',
            last_name='Alioune',
            role='civil_admin',
            commune=self.commune
        )

    def _create_dossier(self, dossier_type, metadata):
        return Dossier.objects.create(
            type=dossier_type,
            status=Dossier.Status.APPROVED,
            citizen=self.citizen,
            commune=self.commune,
            metadata=metadata,
            completed_at=timezone.now()
        )

    def test_generate_birth_certificate(self):
        dossier = self._create_dossier(Dossier.Type.BIRTH_CERTIFICATE, {
            'prenoms_enfant': 'Saliou',
            'nom_enfant': 'Diop',
            'date_naissance_personne': '2000-01-01',
            'sexe': 'Masculin'
        })
        cert = generate_signed_certificate(dossier, self.officier)
        self.assertIsNotNone(cert)
        self.assertIsNotNone(cert.pdf_file)
        self.assertTrue(cert.pdf_file.name.endswith('.pdf'))
        self.assertIsNotNone(cert.hmac_signature)

    def test_generate_marriage_certificate(self):
        dossier = self._create_dossier(Dossier.Type.MARRIAGE_CERTIFICATE, {
            'lieu_mariage': 'Dakar',
            'date_mariage': '2020-05-15',
            'epoux_1_nom_complet': 'Alioune Sene',
            'epoux_2_nom_complet': 'Fatou Ndiaye'
        })
        cert = generate_signed_certificate(dossier, self.officier)
        self.assertIsNotNone(cert)
        self.assertTrue(cert.pdf_file.name.endswith('.pdf'))

    def test_generate_death_certificate(self):
        dossier = self._create_dossier(Dossier.Type.DEATH_CERTIFICATE, {
            'prenoms_defunt': 'Modou',
            'nom_defunt': 'Fall',
            'date_deces': '2025-01-01',
            'lieu_deces': 'Thies'
        })
        cert = generate_signed_certificate(dossier, self.officier)
        self.assertIsNotNone(cert)
        self.assertTrue(cert.pdf_file.name.endswith('.pdf'))

    def test_generate_residence_certificate(self):
        dossier = self._create_dossier(Dossier.Type.RESIDENCE_CERTIFICATE, {
            'adresse_residence': 'Medina Rue 11',
            'profession_demandeur': 'Ingénieur'
        })
        cert = generate_signed_certificate(dossier, self.officier)
        self.assertIsNotNone(cert)
        self.assertTrue(cert.pdf_file.name.endswith('.pdf'))
