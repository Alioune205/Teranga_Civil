"""
documents/views.py — TERANGA CIVIL (DEV 1C)
=========================================
Vues de gestion des documents téléversés.

Endpoints exposés :
  POST   /api/documents/          → Téléverser un document (alias create)
  POST   /api/documents/upload/   → Téléverser (action dédiée, même logique)
  GET    /api/documents/          → Lister les documents accessibles
  GET    /api/documents/{id}/     → Détail d'un document
  GET    /api/documents/{id}/download/ → Téléchargement sécurisé
  DELETE /api/documents/{id}/     → Supprimer un document

Sécurité :
  - Authentification JWT obligatoire (IsAuthenticated global)
  - Contrôle d'accès par rôle (citoyen / agent communal / super_admin)
  - Protection contre les doublons par comparaison SHA256
  - Analyse antivirus intégrée (scan_file, activable via CLAMAV_ENABLED)
  - Journalisation de chaque upload, téléchargement et refus
"""

import logging

from django.http import FileResponse

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser

from drf_spectacular.utils import extend_schema_view, extend_schema, OpenApiParameter

from apps.audit_logs.models import AuditLog
from apps.shared.responses import success_response, error_response
from apps.shared.utils import get_client_ip

from .models import Document
from .permissions import DocumentAccessPermission, IsDocumentOwner
from .security import scan_file, compute_sha256
from .serializers import (
    DocumentSerializer,
    DocumentUploadSerializer,
    DocumentListSerializer,
)

# Logger principal pour ce module — configuré dans settings LOGGING
logger = logging.getLogger(__name__)


# ==============================================================================
# VIEWSET DOCUMENTS
# ==============================================================================

@extend_schema_view(
    list=extend_schema(
        tags=['Documents'],
        summary='Lister les documents accessibles',
        description=(
            'Retourne la liste des documents auxquels l\'utilisateur a accès '
            'selon son rôle (citoyen → ses propres documents, agent → documents de sa commune).'
        ),
    ),
    retrieve=extend_schema(
        tags=['Documents'],
        summary='Détail d\'un document',
    ),
    create=extend_schema(
        tags=['Documents'],
        summary='Téléverser un document',
        description=(
            'Téléverse un fichier lié à un dossier. '
            'Formats acceptés : PDF, PNG, JPEG. Taille max : 10 Mo. '
            'La validation inclut la vérification des Magic Bytes et la détection de doublons (SHA256).'
        ),
    ),
    destroy=extend_schema(
        tags=['Documents'],
        summary='Supprimer un document',
    ),
)
class DocumentViewSet(viewsets.ModelViewSet):
    """
    ViewSet complet pour la gestion des documents téléversés.

    Gestion des accès selon le rôle :
      - Citoyen   : voit et gère ses propres documents uniquement.
      - Agent     : voit les documents des dossiers de sa commune.
      - SuperAdmin: accès total (lecture, suppression).

    Fonctionnalités de sécurité :
      - Validation fichier (taille, magic bytes, extension) via validate_uploaded_file
      - Calcul et stockage du SHA256 pour intégrité et anti-doublon
      - Analyse antivirus (ClamAV, activable en production)
      - Journalisation de tous les accès et erreurs
    """

    # Méthodes HTTP autorisées (pas de PATCH/PUT — les documents sont immuables)
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    # Parseurs multipart pour la réception des fichiers uploadés
    parser_classes = [MultiPartParser, FormParser]

    # Champs de filtrage disponibles via ?dossier=<uuid>&file_type=pdf
    filterset_fields = ['dossier', 'file_type', 'ocr_status']

    # Champs de recherche textuelle via ?search=<terme>
    search_fields = ['original_filename', 'description']

    # Tri par défaut : les plus récents en premier
    ordering = ['-created_at']

    # ------------------------------------------------------------------
    # QUERYSET — Filtrage selon le rôle utilisateur
    # ------------------------------------------------------------------

    def get_queryset(self):
        """
        Retourne le queryset filtré selon le rôle de l'utilisateur connecté.

        Pour la plupart des actions, nous limitons les résultats aux documents
        que l'utilisateur est censé voir. Pour l'action de téléchargement,
        nous utilisons par contre le queryset complet afin que la permission
        objet puisse renvoyer un 403 et non un 404.

        Politique d'accès aux données :
          - Citoyen      : uniquement les documents de ses propres dossiers
          - Agent/Admin  : documents des dossiers de sa commune assignée
          - Super Admin  : tous les documents (accès global)
          - Autres       : aucun document (queryset vide)

        Returns:
            QuerySet: Documents filtrés selon les droits de l'utilisateur.
        """
        user = self.request.user

        # Optimisation : select_related pour éviter les requêtes N+1
        qs = Document.objects.select_related('dossier', 'uploaded_by', 'dossier__commune')

        if self.action == 'download':
            # Pour l'action download, n'appliquer aucun filtre de queryset ici.
            # Le contrôle d'accès est exécuté ensuite dans DocumentAccessPermission.
            return qs.all()

        if getattr(user, 'role', None) == 'citizen':
            # Le citoyen ne voit que les documents de ses dossiers
            return qs.filter(dossier__citizen=user)

        elif getattr(user, 'is_admin_staff', False) and getattr(user, 'commune', None):
            # L'agent voit les documents de sa commune
            return qs.filter(dossier__commune=user.commune)

        elif getattr(user, 'role', None) == 'super_admin':
            # Super admin : accès complet
            return qs.all()

        # Cas par défaut : accès refusé (queryset vide)
        return qs.none()

    def get_serializer_class(self):
        """
        Retourne le sérialiseur approprié selon l'action en cours.

        - create / upload : DocumentUploadSerializer (entrée minimale : dossier + file)
        - list            : DocumentListSerializer (vue allégée, sans contenu OCR)
        - autres          : DocumentSerializer (vue complète)
        """
        if self.action in ('create', 'upload'):
            return DocumentUploadSerializer
        if self.action == 'list':
            return DocumentListSerializer
        return DocumentSerializer

    def get_permissions(self):
        """
        Retourne les classes de permissions selon l'action.

        Politique :
          - download        : IsAuthenticated + DocumentAccessPermission (contrôle objet)
          - destroy         : IsAuthenticated + IsDocumentOwner
          - autres          : IsAuthenticated uniquement (le queryset filtre déjà)
        """
        if self.action == 'download':
            return [IsAuthenticated(), DocumentAccessPermission()]
        if self.action == 'destroy':
            return [IsAuthenticated(), IsDocumentOwner()]
        return [IsAuthenticated()]

    # ------------------------------------------------------------------
    # TÂCHE 3 : UPLOAD SÉCURISÉ
    # POST /api/documents/          (action create standard)
    # POST /api/documents/upload/   (action dédiée — même logique)
    # ------------------------------------------------------------------

    def create(self, request, *args, **kwargs):
        """
        Téléverse un nouveau document de manière sécurisée.

        Processus en 5 étapes :
          1. Validation du fichier (taille, magic bytes, extension)
          2. Analyse antivirus (ClamAV si activé)
          3. Calcul du hash SHA256
          4. Détection des doublons
          5. Enregistrement en base et retour JSON

        Args:
            request: Requête multipart/form-data avec 'file' et 'dossier'.

        Returns:
            Response: JSON avec document_id, filename, hash (HTTP 201)
                      ou message d'erreur (HTTP 400/409/500).
        """
        return self._process_upload(request)

    @extend_schema(
        tags=['Documents'],
        summary='Téléverser un document (endpoint dédié)',
        description=(
            'Endpoint dédié à l\'upload. Identique à POST /api/documents/ '
            'mais avec une URL sémantiquement explicite pour les intégrations frontend.'
        ),
    )
    @action(
        detail=False,
        methods=['post'],
        url_path='upload',
        parser_classes=[MultiPartParser, FormParser],
    )
    def upload(self, request):
        """
        Action dédiée : POST /api/documents/upload/

        Offre une URL sémantique pour les intégrations frontend/mobile.
        Délègue au même pipeline que create().
        """
        return self._process_upload(request)

    def _process_upload(self, request):
        """
        Pipeline centralisé de traitement des uploads de documents.

        Factorisation de la logique partagée entre create() et upload()
        pour éviter la duplication de code (principe DRY).

        Étapes :
          1. Désérialisation et validation des données (dossier, fichier)
          2. Analyse antivirus ClamAV (si CLAMAV_ENABLED=True)
          3. Calcul du hash SHA256 du fichier
          4. Vérification de doublon via SHA256
          5. Persistance en base de données
          6. Retour de la réponse JSON standardisée

        Args:
            request: Requête DRF avec fichier et métadonnées.

        Returns:
            Response: JSON {success, document_id, filename, hash, mime_type}
        """
        # ----------------------------------------------------------------
        # ÉTAPE 1 : Validation des données d'entrée
        # Le sérialiseur applique validate_uploaded_file via le FileField du modèle
        # (magic bytes, taille, extension dangereuse)
        # ----------------------------------------------------------------
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        uploaded_file = serializer.validated_data.get('file')

        # ----------------------------------------------------------------
        # ÉTAPE 2 : Analyse antivirus (ClamAV)
        # Désactivée par défaut (CLAMAV_ENABLED=False) pour le MVP.
        # En production : définir CLAMAV_ENABLED=True dans .env
        # ----------------------------------------------------------------
        scan_result = scan_file(uploaded_file)
        if scan_result['status'] != 'OK':
            logger.warning(
                f"[UPLOAD][BLOQUE] Fichier rejeté par antivirus pour {request.user.email}. "
                f"Menace : {scan_result.get('threat')} — {scan_result['message']}"
            )
            return error_response(
                message=scan_result['message'],
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        # ----------------------------------------------------------------
        # ÉTAPE 3 : Calcul du hash SHA256 du contenu binaire
        # Utilise la fonction centralisée de security.py (lecture par chunks)
        # ----------------------------------------------------------------
        file_hash = compute_sha256(uploaded_file)

        # ----------------------------------------------------------------
        # ÉTAPE 4 : Détection des doublons par comparaison de hash SHA256
        # Un même fichier ne doit pas être téléversé deux fois.
        # Retourne un avertissement (409 Conflict) sans bloquer les ops légitimes.
        # ----------------------------------------------------------------
        existing_duplicate = Document.objects.filter(sha256_hash=file_hash).first()
        if existing_duplicate:
            logger.warning(
                f"[UPLOAD][DOUBLON] Tentative d'upload d'un fichier identique par "
                f"'{request.user.email}'. Hash SHA256 : {file_hash}. "
                f"Document existant ID : {existing_duplicate.id}."
            )
            return error_response(
                message=(
                    f"Avertissement : un fichier identique existe déjà "
                    f"(réf. document #{existing_duplicate.id}). "
                    f"Veuillez vérifier que vous n'avez pas déjà soumis ce fichier."
                ),
                status_code=status.HTTP_409_CONFLICT,
            )

        # ----------------------------------------------------------------
        # ÉTAPE 5 : Enregistrement en base de données
        # Le hash calculé et le MIME type sont passés directement pour éviter
        # un double calcul dans save().
        # ----------------------------------------------------------------
        # Récupérer le MIME type déclaré par le client (ou inféré par Django)
        file_mime = getattr(uploaded_file, 'content_type', '') or ''

        document = serializer.save(
            sha256_hash=file_hash,
            mime_type=file_mime,
        )

        # Journalisation de l'upload réussi
        logger.info(
            f"[UPLOAD][OK] Document '{document.original_filename}' téléversé avec succès "
            f"par '{request.user.email}'. ID : {document.id}, Hash : {file_hash}, "
            f"Taille : {document.file_size} octets, MIME : {document.mime_type}."
        )

        # Audit log pour le téléversement de document
        AuditLog.log(
            user=request.user,
            action=AuditLog.Action.UPLOAD,
            resource_type='document',
            resource_id=document.id,
            details={
                'filename': document.original_filename,
                'dossier_id': str(document.dossier_id),
                'mime_type': document.mime_type,
                'file_size': document.file_size,
            },
            ip_address=get_client_ip(request),
        )

        # ----------------------------------------------------------------
        # ÉTAPE 6 : Retour JSON standardisé selon la spécification DEV 1C
        # ----------------------------------------------------------------
        return success_response(
            data={
                'success': True,
                'document_id': str(document.id),
                'filename': document.original_filename,
                'hash': document.sha256_hash,
                'mime_type': document.mime_type,
                'file_size': document.file_size,
                'dossier': str(document.dossier_id),
            },
            message='Document téléversé avec succès.',
            status_code=status.HTTP_201_CREATED,
        )

    # ------------------------------------------------------------------
    # TÂCHE 4 : TÉLÉCHARGEMENT SÉCURISÉ
    # GET /api/documents/{id}/download/
    # ------------------------------------------------------------------

    @extend_schema(
        tags=['Documents'],
        summary='Télécharger un document',
        description=(
            'Télécharger le fichier d\'un document. '
            'Accès restreint au propriétaire du dossier ou aux agents de la même commune.'
        ),
        parameters=[
            OpenApiParameter(name='id', location='path', description='UUID du document', required=True),
        ],
    )
    @action(detail=True, methods=['get'], url_path='download')
    def download(self, request, pk=None):
        """
        Téléchargement sécurisé d'un document.

        Contrôle d'accès (géré par DocumentAccessPermission) :
          - Le citoyen propriétaire du dossier
          - Les agents de la même commune
          - Les super_admins

        La permission has_object_permission() est appelée automatiquement
        par get_object() via check_object_permissions().

        Returns:
            FileResponse: Fichier en pièce jointe (Content-Disposition: attachment)
            Response: 403 si accès refusé, 500 si erreur de lecture
        """
        # get_object() appelle automatiquement check_object_permissions()
        # qui déclenche DocumentAccessPermission.has_object_permission()
        instance = self.get_object()

        try:
            from django.conf import settings
            from django.http import HttpResponse

            if not settings.DEBUG:
                # Production: délégation à Nginx via X-Accel-Redirect
                content_type = instance.mime_type or 'application/octet-stream'
                response = HttpResponse(content_type=content_type)
                response['X-Accel-Redirect'] = instance.file.url
                response['Content-Disposition'] = f'inline; filename="{instance.original_filename}"'
            else:
                # Développement: FileResponse direct
                content_type = instance.mime_type or 'application/octet-stream'
                response = FileResponse(
                    instance.file.open('rb'),
                    as_attachment=False,
                    filename=instance.original_filename,
                    content_type=content_type,
                )

            # Journalisation du téléchargement réussi
            logger.info(
                f"[DOWNLOAD][OK] Document '{instance.original_filename}' (ID: {instance.id}) "
                f"téléchargé par '{request.user.email}'."
            )

            AuditLog.log(
                user=request.user,
                action=AuditLog.Action.DOWNLOAD,
                resource_type='document',
                resource_id=instance.id,
                details={
                    'filename': instance.original_filename,
                    'dossier_id': str(instance.dossier_id),
                    'mime_type': instance.mime_type,
                },
                ip_address=get_client_ip(request),
            )
            return response

        except FileNotFoundError:
            # Le fichier physique est introuvable sur le disque / S3
            logger.error(
                f"[DOWNLOAD][ERREUR] Fichier physique introuvable pour le document {instance.id} "
                f"(chemin: {instance.file.name}). Demandé par '{request.user.email}'."
            )
            return error_response(
                message="Le fichier demandé est introuvable. Contacter l'administrateur.",
                status_code=status.HTTP_404_NOT_FOUND,
            )

        except Exception as e:
            logger.exception(
                f"[DOWNLOAD][ERREUR] Échec du téléchargement du document {instance.id} "
                f"par '{request.user.email}' : {str(e)}"
            )
            return error_response(
                message="Erreur lors du téléchargement du fichier.",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    # ------------------------------------------------------------------
    # ACTIONS STANDARD
    # ------------------------------------------------------------------

    def retrieve(self, request, *args, **kwargs):
        """Retourne les métadonnées complètes d'un document."""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)

    def list(self, request, *args, **kwargs):
        """Liste paginée des documents accessibles à l'utilisateur."""
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return success_response(data=serializer.data)

    def destroy(self, request, *args, **kwargs):
        """
        Suppression d'un document.

        Restreint au propriétaire, aux civil_admin et super_admin
        (géré par la permission IsDocumentOwner dans get_permissions()).
        """
        instance = self.get_object()
        doc_id = instance.id
        filename = instance.original_filename

        instance.delete()

        logger.info(
            f"[DELETE][OK] Document '{filename}' (ID: {doc_id}) "
            f"supprimé par '{request.user.email}'."
        )

        AuditLog.log(
            user=request.user,
            action=AuditLog.Action.DELETE,
            resource_type='document',
            resource_id=doc_id,
            details={
                'filename': filename,
                'dossier_id': str(instance.dossier_id),
            },
            ip_address=get_client_ip(request),
        )
        return success_response(
            message='Document supprimé avec succès.',
            status_code=status.HTTP_200_OK,
        )
