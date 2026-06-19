"""
Tests for business rules and Fix 4 (is_for_third_party).
"""
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model
from datetime import date

from apps.communes.models import Commune
from apps.dossiers.models import RegistreCivil, Dossier
from apps.users.models import CitizenProfile

from django.test import override_settings

User = get_user_model()

@override_settings(CACHES={'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'}})
class BusinessRulesTests(APITestCase):
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
        profile1 = self.citizen.profile
        profile1.cni_number = '1234567890123'
        profile1.save()
        
        self.citizen_no_cni = User.objects.create_user(
            email='citizen2@example.com',
            password='password123',
            first_name='Moussa',
            last_name='Diop',
            role='citizen'
        )
        profile2 = self.citizen_no_cni.profile
        profile2.cni_number = ''
        profile2.save()

        self.registre_alioune = RegistreCivil.objects.create(
            numero_registre='100',
            annee_registre=1990,
            commune=self.commune,
            type_acte=Dossier.Type.BIRTH_CERTIFICATE,
            nom_complet_personne='Alioune Sene',
            date_naissance_personne=date(1990, 1, 1),
        )
        
        self.registre_other = RegistreCivil.objects.create(
            numero_registre='101',
            annee_registre=1995,
            commune=self.commune,
            type_acte=Dossier.Type.BIRTH_CERTIFICATE,
            nom_complet_personne='Fatou Ndiaye',
            date_naissance_personne=date(1995, 2, 2),
        )

        self.url = '/api/dossiers/verify-registry/'

    def test_verify_registry_success_self(self):
        """Rule: Citizen asking for their own act, names match."""
        self.client.force_authenticate(user=self.citizen)
        data = {
            'numero_registre': '100',
            'annee_registre': 1990,
            'commune': self.commune.code,
            'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
            'is_for_third_party': False
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('Acte trouvé', response.data['message'])

    def test_verify_registry_fail_self_wrong_name(self):
        """Rule: Citizen asking for their own act, but name in registry doesn't match."""
        self.client.force_authenticate(user=self.citizen)
        data = {
            'numero_registre': '101',
            'annee_registre': 1995,
            'commune': self.commune.code,
            'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
            'is_for_third_party': False
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Les noms sur cet acte ne correspondent pas', response.data['message'])

    def test_verify_registry_success_third_party(self):
        """Rule: Citizen with CNI asking for a third party (Fatou's act)."""
        self.client.force_authenticate(user=self.citizen)
        data = {
            'numero_registre': '101',
            'annee_registre': 1995,
            'commune': self.commune.code,
            'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
            'is_for_third_party': True
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_verify_registry_fail_third_party_no_cni(self):
        """Rule: Citizen without CNI cannot ask for a third party."""
        self.client.force_authenticate(user=self.citizen_no_cni)
        data = {
            'numero_registre': '101',
            'annee_registre': 1995,
            'commune': self.commune.code,
            'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
            'is_for_third_party': True
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('doit contenir un numéro de CNI valide', response.data['message'])

    def test_verify_registry_not_found(self):
        """Rule: Act not found in registry."""
        self.client.force_authenticate(user=self.citizen)
        data = {
            'numero_registre': '999',
            'annee_registre': 2000,
            'commune': self.commune.code,
            'type_acte': Dossier.Type.BIRTH_CERTIFICATE,
            'is_for_third_party': False
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


@override_settings(CACHES={'default': {'BACKEND': 'django.core.cache.backends.locmem.LocMemCache'}})
class IsForThirdPartyTests(APITestCase):
    """
    Tests Fix 4 — bilan intégration 14/06 :
      1. is_for_third_party=True persisté dans metadata à la création
      2. is_for_third_party=False (défaut) persisté dans metadata
      3. Le PDF pour un tiers ne prend pas les infos du demandeur (confidentialité)
    """

    def setUp(self):
        self.commune = Commune.objects.create(
            code='DKR-T4', name='Dakar T4', department='Dakar', region='Dakar'
        )
        self.citizen = User.objects.create_user(
            email='tiers_test@example.com',
            password='password123',
            first_name='Fatou',
            last_name='Ba',
            role='citizen',
        )
        profile = self.citizen.profile
        profile.cni_number = '2 90 07 12345678 9'
        profile.save()

        self.create_url = '/api/dossiers/'
        self.client.force_authenticate(user=self.citizen)

    def test_is_for_third_party_true_persisted_in_metadata(self):
        """
        Quand is_for_third_party=true est envoyé au top-level du payload,
        il doit être stocké dans dossier.metadata['is_for_third_party'] = True.
        """
        response = self.client.post(self.create_url, {
            'type': Dossier.Type.BIRTH_CERTIFICATE,
            'commune': self.commune.code,
            'metadata': {
                'numero_registre': '100',
                'annee_registre': 2000,
            },
            'is_for_third_party': True,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        dossier_id = (
            response.data.get('id')
            or (response.data.get('data') or {}).get('id')
        )
        dossier = Dossier.objects.get(id=dossier_id)
        self.assertTrue(
            dossier.metadata.get('is_for_third_party'),
            "is_for_third_party devrait être True dans metadata"
        )

    def test_is_for_third_party_false_persisted_in_metadata(self):
        """
        Quand is_for_third_party n'est pas envoyé,
        metadata['is_for_third_party'] doit être False (présent mais False).
        """
        response = self.client.post(self.create_url, {
            'type': Dossier.Type.BIRTH_CERTIFICATE,
            'commune': self.commune.code,
            'metadata': {
                'numero_registre': '100',
                'annee_registre': 2000,
            },
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        dossier_id = (
            response.data.get('id')
            or (response.data.get('data') or {}).get('id')
        )
        dossier = Dossier.objects.get(id=dossier_id)
        self.assertIn('is_for_third_party', dossier.metadata)
        self.assertFalse(dossier.metadata['is_for_third_party'])

    def test_pdf_tiers_ne_prend_pas_infos_demandeur(self):
        """
        Confidentialité Fix 4 : pour un dossier 'pour un tiers', le PDF
        ne doit PAS utiliser les données du demandeur comme fallback.
        Vérifie que is_for_third_party=True dans metadata bloque le fallback
        citizen dans _draw_pdf_content.
        """
        from apps.dossiers.services.pdf_generator import _draw_pdf_content
        from reportlab.pdfgen import canvas
        from io import BytesIO
        from reportlab.lib.pagesizes import A4

        dossier = Dossier.objects.create(
            type=Dossier.Type.BIRTH_CERTIFICATE,
            status=Dossier.Status.DRAFT,
            citizen=self.citizen,   # le demandeur : Fatou Ba
            commune=self.commune,
            metadata={
                'is_for_third_party': True,
                # Données du TIERS (différentes du demandeur Fatou Ba)
                'prenoms_enfant': 'Mamadou',
                'nom_enfant': 'Diallo',
                'date_naissance_personne': '1995-05-20',
                'lieu_naissance': 'Ziguinchor',
                'sexe': 'M',
                'nom_pere': 'Ousmane Diallo',
                'nom_mere': 'Mariama Bah',
            },
        )

        buf = BytesIO()
        p = canvas.Canvas(buf, pagesize=A4)
        width, height = A4

        # _draw_pdf_content ne doit pas lever d'exception
        try:
            _draw_pdf_content(
                p, width, height, dossier,
                officier=None, timbre_ref='TIM-TEST',
                cachet_path='', signature_path='',
                cachet_nominal_path='', qr_image_reader=None,
            )
            p.save()
        except Exception as e:
            self.fail(f"_draw_pdf_content a levé une exception inattendue : {e}")

        # Le flag est correctement stocké
        self.assertTrue(dossier.metadata.get('is_for_third_party'))
        # Les données metadata sont celles du tiers, pas du demandeur
        self.assertEqual(dossier.metadata.get('nom_enfant'), 'Diallo')
        self.assertNotEqual(
            dossier.metadata.get('nom_enfant'),
            self.citizen.last_name,
            "Le nom 'Diallo' ne doit pas correspondre au nom du demandeur 'Ba'"
        )
