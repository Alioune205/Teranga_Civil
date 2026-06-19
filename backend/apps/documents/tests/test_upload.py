"""
tests/test_upload.py — Tests du pipeline d'upload de documents.
Couvre les 4 flux demandés dans le bilan intégration du 14/06 :
  1. Upload CNI → naissance pour soi-même
  2. Upload CNI → naissance pour un tiers
  3. Upload constat médecin → décès
  4. Upload extrait → mariage

Vérifie : HTTP 201, document attaché au dossier, sha256_hash et mime_type renseignés.
"""
import io
import hashlib
from datetime import date, timedelta
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model

from apps.communes.models import Commune
from apps.dossiers.models import Dossier
from apps.documents.models import Document

User = get_user_model()

# On utilise un storage en mémoire pour éviter les effets de bord sur le FS
@override_settings(
    DEFAULT_FILE_STORAGE='django.core.files.storage.InMemoryStorage',
    MEDIA_ROOT='/tmp/teranga_test_media/',
    CACHES={'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'}},
)
class DocumentUploadTests(APITestCase):
    """Tests d'upload pour les 4 types de dossiers."""

    def setUp(self):
        self.commune = Commune.objects.create(
            code='DKR-TST',
            name='Dakar Test',
            department='Dakar',
            region='Dakar',
        )
        # Citoyen demandeur (avec CNI pour les demandes tiers)
        self.citizen = User.objects.create_user(
            email='upload_test@example.com',
            password='password123',
            first_name='Alioune',
            last_name='Sene',
            role='citizen',
        )
        profile = self.citizen.profile
        profile.cni_number = '1 99 12 34567890 1'
        profile.save()

        # Dossier naissance pour soi
        self.dossier_naissance_self = Dossier.objects.create(
            type=Dossier.Type.BIRTH_CERTIFICATE,
            status=Dossier.Status.DRAFT,
            citizen=self.citizen,
            commune=self.commune,
            metadata={'is_for_third_party': False},
        )
        # Dossier naissance pour un tiers
        self.dossier_naissance_tiers = Dossier.objects.create(
            type=Dossier.Type.BIRTH_CERTIFICATE,
            status=Dossier.Status.DRAFT,
            citizen=self.citizen,
            commune=self.commune,
            metadata={'is_for_third_party': True},
        )
        # Dossier décès
        self.dossier_deces = Dossier.objects.create(
            type=Dossier.Type.DEATH_CERTIFICATE,
            status=Dossier.Status.DRAFT,
            citizen=self.citizen,
            commune=self.commune,
            metadata={
                'date_deces': (date.today() - timedelta(days=10)).isoformat(),
                'constat_medecin': 'pending',
                'cni_defunt': 'pending',
            },
        )
        # Dossier mariage
        self.dossier_mariage = Dossier.objects.create(
            type=Dossier.Type.MARRIAGE_CERTIFICATE,
            status=Dossier.Status.DRAFT,
            citizen=self.citizen,
            commune=self.commune,
            metadata={
                'cni_epoux': 'pending',
                'cni_epouse': 'pending',
                'cni_temoins': 'pending',
            },
        )
        self.upload_url = '/api/documents/upload/'
        self.client.force_authenticate(user=self.citizen)

    def _make_fake_file(self, name='test_cni.jpg', content=b'fakeimagecontent', content_type='image/jpeg'):
        """Crée un fichier en mémoire simulant un upload réel."""
        f = io.BytesIO(content)
        f.name = name
        f.content_type = content_type
        return f

    def _expected_hash(self, content):
        return hashlib.sha256(content).hexdigest()

    # ------------------------------------------------------------------
    # FLUX 1 : Upload CNI pour soi-même (naissance)
    # ------------------------------------------------------------------
    def test_upload_cni_naissance_self_returns_201(self):
        """Upload CNI pour un dossier de naissance (demande perso) → 201."""
        content = b'fakeCNIcontent_self'
        fake_file = self._make_fake_file('cni_self.jpg', content, 'image/jpeg')

        response = self.client.post(
            self.upload_url,
            {'file': fake_file, 'dossier': str(self.dossier_naissance_self.id)},
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        doc_id = response.data.get('data', {}).get('document_id') or response.data.get('document_id')
        self.assertIsNotNone(doc_id, "document_id absent de la réponse")

        doc = Document.objects.get(id=doc_id)
        self.assertEqual(doc.dossier, self.dossier_naissance_self)
        self.assertEqual(doc.sha256_hash, self._expected_hash(content))
        self.assertIn('image', doc.mime_type)

    # ------------------------------------------------------------------
    # FLUX 2 : Upload CNI pour un tiers (naissance)
    # ------------------------------------------------------------------
    def test_upload_cni_naissance_tiers_returns_201(self):
        """Upload CNI pour un dossier de naissance tiers → 201, document attaché."""
        content = b'fakeCNIcontent_tiers'
        fake_file = self._make_fake_file('cni_tiers.jpg', content, 'image/jpeg')

        response = self.client.post(
            self.upload_url,
            {'file': fake_file, 'dossier': str(self.dossier_naissance_tiers.id)},
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        doc_id = response.data.get('data', {}).get('document_id') or response.data.get('document_id')
        doc = Document.objects.get(id=doc_id)
        self.assertEqual(doc.dossier, self.dossier_naissance_tiers)
        self.assertEqual(doc.sha256_hash, self._expected_hash(content))

    # ------------------------------------------------------------------
    # FLUX 3 : Upload constat médecin (décès)
    # ------------------------------------------------------------------
    def test_upload_constat_deces_returns_201(self):
        """Upload constat médecin pour un dossier de décès → 201."""
        content = b'fakeConstatContent'
        fake_file = self._make_fake_file('constat_medecin.pdf', content, 'application/pdf')

        response = self.client.post(
            self.upload_url,
            {'file': fake_file, 'dossier': str(self.dossier_deces.id)},
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        doc_id = response.data.get('data', {}).get('document_id') or response.data.get('document_id')
        doc = Document.objects.get(id=doc_id)
        self.assertEqual(doc.dossier, self.dossier_deces)
        self.assertEqual(doc.sha256_hash, self._expected_hash(content))

    # ------------------------------------------------------------------
    # FLUX 4 : Upload extrait de naissance (mariage)
    # ------------------------------------------------------------------
    def test_upload_extrait_mariage_returns_201(self):
        """Upload extrait de naissance pour un dossier de mariage → 201."""
        content = b'fakeExtraitContent'
        fake_file = self._make_fake_file('extrait_naissance.pdf', content, 'application/pdf')

        response = self.client.post(
            self.upload_url,
            {'file': fake_file, 'dossier': str(self.dossier_mariage.id)},
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)

        doc_id = response.data.get('data', {}).get('document_id') or response.data.get('document_id')
        doc = Document.objects.get(id=doc_id)
        self.assertEqual(doc.dossier, self.dossier_mariage)
        self.assertEqual(doc.sha256_hash, self._expected_hash(content))

    # ------------------------------------------------------------------
    # DOUBLON : même fichier uploadé deux fois → 409
    # ------------------------------------------------------------------
    def test_upload_duplicate_returns_409(self):
        """Uploader deux fois le même fichier doit retourner 409 Conflict."""
        content = b'exactSameBinaryContent'

        fake_file_1 = self._make_fake_file('doc1.jpg', content, 'image/jpeg')
        r1 = self.client.post(
            self.upload_url,
            {'file': fake_file_1, 'dossier': str(self.dossier_naissance_self.id)},
            format='multipart',
        )
        self.assertEqual(r1.status_code, status.HTTP_201_CREATED, r1.data)

        fake_file_2 = self._make_fake_file('doc2.jpg', content, 'image/jpeg')
        r2 = self.client.post(
            self.upload_url,
            {'file': fake_file_2, 'dossier': str(self.dossier_naissance_self.id)},
            format='multipart',
        )
        self.assertEqual(r2.status_code, status.HTTP_409_CONFLICT, r2.data)
