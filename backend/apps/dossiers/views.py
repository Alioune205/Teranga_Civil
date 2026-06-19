"""
Views for Dossier management with workflow actions.
"""
from django.utils import timezone

from rest_framework import viewsets, status, filters
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema_view, extend_schema, OpenApiResponse

from django.contrib.auth import get_user_model

from apps.shared.permissions import (
    IsCitizen,
    IsAdminStaff,
    IsCivilAdmin,
    IsSuperAdmin,
    IsReceptionAgent,
    IsAgent,
    IsVerificationAgent,
    IsApprovalAgent,
)
from apps.shared.responses import success_response, error_response

from .models import Dossier, RegistreCivil
from .serializers import (
    DossierCreateSerializer,
    DossierListSerializer,
    DossierDetailSerializer,
    DossierUpdateSerializer,
    DossierCommentSerializer,
    DossierAssignSerializer,
    DossierRejectSerializer,
)

User = get_user_model()


@extend_schema_view(
    list=extend_schema(tags=['Dossiers'], summary='Lister les dossiers'),
    retrieve=extend_schema(tags=['Dossiers'], summary='Détail d\'un dossier'),
    create=extend_schema(tags=['Dossiers'], summary='Créer un dossier'),
    partial_update=extend_schema(tags=['Dossiers'], summary='Modifier un dossier'),
)
class DossierViewSet(viewsets.ModelViewSet):
    """
    ViewSet for dossier management.
    Citizens see their own dossiers; agents see dossiers from their commune.
    """
    http_method_names = ['get', 'post', 'patch', 'delete']
    filterset_fields = ['type', 'status', 'commune']
    search_fields = ['reference', 'citizen__first_name', 'citizen__last_name']
    ordering_fields = ['created_at', 'submitted_at', 'status']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        qs = Dossier.objects.select_related(
            'citizen', 'assigned_agent', 'commune', 'citoyen_guichet'
        ).prefetch_related('comments', 'documents')

        if user.role == 'citizen':
            from django.db.models import Q
            q = Q(citizen=user)
            cni = getattr(user.profile, 'cni_number', None) if hasattr(user, 'profile') else None
            if cni:
                q |= Q(citoyen_guichet__numero_cni=cni)
            if user.phone:
                q |= Q(citoyen_guichet__telephone=user.phone)
            if user.email:
                q |= Q(citoyen_guichet__email=user.email)
            return qs.filter(q)
        elif user.role == 'super_admin':
            return qs.all()
        elif user.role == 'agent':
            return qs.filter(assigned_agent=user)
        elif user.is_admin_staff and user.commune:
            return qs.filter(commune=user.commune)
        return qs.none()

    def get_serializer_class(self):
        if self.action == 'create':
            return DossierCreateSerializer
        if self.action == 'list':
            return DossierListSerializer
        if self.action == 'partial_update':
            return DossierUpdateSerializer
        return DossierDetailSerializer

    def get_permissions(self):
        if self.action == 'create':
            return [IsAuthenticated(), IsCitizen()]
        return super().get_permissions()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        dossier = serializer.save()
        
        # --- NOUVEAU : Enrichissement via RegistreCivil ---
        numero = dossier.metadata.get('numero_registre')
        annee = dossier.metadata.get('annee_registre')
        
        if numero and annee:
            try:
                registre = RegistreCivil.objects.get(
                    numero_registre=numero,
                    annee_registre=annee,
                    commune=dossier.commune,
                    type_acte=dossier.type
                )
                
                champs_a_copier = {
                    'nom_complet_personne': 'nom_complet_personne',
                    'date_naissance_personne': 'date_naissance_personne',
                    'conjoint_nom_complet': 'conjoint_nom_complet',
                    'nom_pere': 'nom_pere',
                    'nom_mere': 'nom_mere',
                    'sexe': 'sexe',
                    'lieu_naissance': 'lieu_naissance',
                    'profession_pere': 'profession_pere',
                    'profession_mere': 'profession_mere'
                }
                
                metadata_mise_a_jour = False
                for champ_reg, champ_meta in champs_a_copier.items():
                    valeur_registre = getattr(registre, champ_reg, None)
                    if valeur_registre is not None and valeur_registre != '':
                        # Normalisation des dates (ex: DateField vers string)
                        valeur_str = str(valeur_registre) if not hasattr(valeur_registre, 'isoformat') else valeur_registre.isoformat()
                        
                        valeur_citoyen = dossier.metadata.get(champ_meta)
                        if not valeur_citoyen:
                            # Champ vide chez le citoyen, on complète
                            dossier.metadata[champ_meta] = valeur_str
                            metadata_mise_a_jour = True
                        elif str(valeur_citoyen) != valeur_str:
                            # Divergence
                            import logging
                            logger = logging.getLogger('audit')
                            logger.warning(
                                f"Divergence RegistreCivil/Citoyen pour le dossier {dossier.reference}. "
                                f"Champ: {champ_meta}. Citoyen: {valeur_citoyen}. Registre: {valeur_str}."
                            )
                            # Log détaillé
                            from apps.audit_logs.models import AuditLog
                            AuditLog.log(
                                user=request.user,
                                action=AuditLog.Action.UPDATE,
                                resource_type='dossier_divergence',
                                resource_id=dossier.id,
                                details={
                                    'field': champ_meta,
                                    'citizen_value': valeur_citoyen,
                                    'registry_value': valeur_str
                                }
                            )
                
                if metadata_mise_a_jour:
                    dossier.save(update_fields=['metadata'])
            
            except RegistreCivil.DoesNotExist:
                pass
        
        # --- NOUVEAU : Envoi du signal Temps Réel (WebSockets) ---
        try:
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync
            
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                'admin_dashboard',
                {
                    'type': 'dashboard_update',
                    'message': 'new_dossier',
                    'data': DossierDetailSerializer(dossier).data
                }
            )
        except Exception as e:
            print(f"Erreur WebSocket: {e}")
            
        return Response(
            {
                'success': True,
                'message': 'Dossier créé avec succès.',
                'data': DossierDetailSerializer(dossier).data,
                'id': str(dossier.id),
                'errors': None,
            },
            status=status.HTTP_201_CREATED,
        )

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        # Citizens can only edit drafts
        if request.user.role == 'citizen' and instance.status != 'draft':
            return error_response(
                message='Vous ne pouvez modifier un dossier que s\'il est en brouillon.',
                status_code=status.HTTP_403_FORBIDDEN,
            )
        if request.user.role == 'citizen' and instance.citizen != request.user:
            return error_response(
                message='Accès interdit.',
                status_code=status.HTTP_403_FORBIDDEN,
            )

        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(
            data=DossierDetailSerializer(instance).data,
            message='Dossier mis à jour avec succès.',
        )

    @extend_schema(
        tags=['Dossiers'],
        summary="Vérifier l'existence d'un acte dans le Registre Civil",
        description="Vérifie si le numéro et l'année existent. Valide aussi la correspondance du nom ou de la CNI.",
        responses={
            200: OpenApiResponse(description='Acte trouvé et vérifié.'),
            400: OpenApiResponse(description='Acte non trouvé ou non correspondant.'),
        },
    )
    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated, IsCitizen | IsReceptionAgent | IsCivilAdmin | IsSuperAdmin], url_path='verify-registry')
    def verify_registry(self, request):
        """POST /api/dossiers/verify-registry/"""
        user = request.user
        
        numero_registre = request.data.get('numero_registre')
        annee_registre = request.data.get('annee_registre')
        commune_id = request.data.get('commune')
        type_acte = request.data.get('type_acte')
        is_for_third_party = str(request.data.get('is_for_third_party', 'false')).lower() == 'true'

        if not all([numero_registre, annee_registre, commune_id, type_acte]):
            return error_response(
                message='numero_registre, annee_registre, commune et type_acte sont obligatoires.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        # Chercher dans la base simulée
        try:
            registre = RegistreCivil.objects.get(
                numero_registre=numero_registre,
                annee_registre=annee_registre,
                commune__code=commune_id,
                type_acte=type_acte
            )
        except RegistreCivil.DoesNotExist:
            return error_response(
                message='Cet acte est introuvable dans le Registre Civil.',
                status_code=status.HTTP_404_NOT_FOUND,
            )

        # Si tierce personne, exiger CNI du demandeur, pas besoin de vérifier le nom de l'acte contre le demandeur.
        if is_for_third_party:
            if not hasattr(user, 'profile') or not user.profile.cni_number:
                return error_response(
                    message='Votre profil doit contenir un numéro de CNI valide pour faire une demande pour autrui.',
                    status_code=status.HTTP_400_BAD_REQUEST,
                )
        else:
            # Demande personnelle : vérifier que le nom correspond à l'utilisateur connecté
            user_nom = user.full_name.lower().strip()
            registre_nom = registre.nom_complet_personne.lower().strip()
            
            # Simple vérification (dans la vraie vie on utilise des algorithmes phonétiques)
            if user_nom not in registre_nom and registre_nom not in user_nom:
                return error_response(
                    message='Les noms sur cet acte ne correspondent pas à votre identité.',
                    status_code=status.HTTP_400_BAD_REQUEST,
                )

        return success_response(
            message='Acte trouvé. Vous pouvez continuer votre demande.'
        )

    # =====================================================
    # WORKFLOW ACTIONS
    # =====================================================

    @extend_schema(tags=['Dossiers'], summary='Soumettre un dossier')
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def submit(self, request, pk=None):
        """POST /api/dossiers/{id}/submit/ — Submit a draft dossier."""
        dossier = self.get_object()

        if dossier.citizen != request.user:
            return error_response(
                message='Seul le propriétaire peut soumettre ce dossier.',
                status_code=status.HTTP_403_FORBIDDEN,
            )
        if dossier.status != Dossier.Status.DRAFT:
            return error_response(
                message='Seul un dossier en brouillon peut être soumis.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        if dossier.type in ['regularisation', 'autorisation_construire', 'mutation_parcelle']:
            if dossier.documents.count() < (3 if dossier.type == 'regularisation' else 12 if dossier.type == 'autorisation_construire' else 6):
                return error_response(
                    message=f'Vous devez fournir les pièces justificatives requises pour soumettre une demande de {dossier.get_type_display()}.',
                    status_code=status.HTTP_400_BAD_REQUEST,
                )

        dossier.status = Dossier.Status.SUBMITTED
        dossier.submitted_at = timezone.now()
        dossier.save(update_fields=['status', 'submitted_at', 'updated_at'])

        if dossier.type == 'regularisation':
            from apps.dossiers.services.add_regularisation_receipt import generate_regularisation_receipt
            try:
                generate_regularisation_receipt(dossier)
            except Exception as e:
                import logging
                logger = logging.getLogger('apps')
                logger.error(f"Erreur génération récépissé régularisation {dossier.reference}: {str(e)}")
        elif dossier.type == 'autorisation_construire':
            from apps.dossiers.services.add_autorisation_receipt import generate_autorisation_receipt
            try:
                generate_autorisation_receipt(dossier)
            except Exception as e:
                import logging
                logger = logging.getLogger('apps')
                logger.error(f"Erreur génération récépissé autorisation construire {dossier.reference}: {str(e)}")
        elif dossier.type == 'mutation_parcelle':
            from apps.dossiers.services.add_mutation_receipt import generate_mutation_receipt
            try:
                generate_mutation_receipt(dossier)
            except Exception as e:
                import logging
                logger = logging.getLogger('apps')
                logger.error(f"Erreur génération récépissé mutation parcelle {dossier.reference}: {str(e)}")

        return success_response(
            data=DossierDetailSerializer(dossier).data,
            message='Dossier soumis avec succès.',
        )

    @extend_schema(tags=['Dossiers'], summary='Assigner un agent', request=DossierAssignSerializer)
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsCivilAdmin | IsSuperAdmin])
    def assign(self, request, pk=None):
        """POST /api/dossiers/{id}/assign/ — Assign an agent."""
        dossier = self.get_object()
        serializer = DossierAssignSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        agent = User.objects.get(id=serializer.validated_data['agent_id'])
        
        if agent.commune != dossier.commune:
            return error_response(
                message="L'agent doit appartenir à la même commune que le dossier.",
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        dossier.assigned_agent = agent
        dossier.save(update_fields=['assigned_agent', 'updated_at'])

        return success_response(
            data=DossierDetailSerializer(dossier).data,
            message=f'Dossier assigné à {agent.full_name}.',
        )

    @extend_schema(tags=['Dossiers'], summary='Mettre en vérification')
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsAgent | IsVerificationAgent | IsCivilAdmin | IsSuperAdmin])
    def review(self, request, pk=None):
        """POST /api/dossiers/{id}/review/ — Move to in_review."""
        dossier = self.get_object()

        if dossier.status != Dossier.Status.SUBMITTED:
            return error_response(
                message='Seul un dossier soumis peut être mis en vérification.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        dossier.status = Dossier.Status.IN_REVIEW
        dossier.reviewed_at = timezone.now()
        dossier.save(update_fields=['status', 'reviewed_at', 'updated_at'])

        return success_response(
            data=DossierDetailSerializer(dossier).data,
            message='Dossier mis en cours de vérification.',
        )

    @extend_schema(tags=['Dossiers'], summary='Approuver un dossier')
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsAgent | IsApprovalAgent | IsCivilAdmin | IsSuperAdmin])
    def approve(self, request, pk=None):
        """POST /api/dossiers/{id}/approve/ — Approve the dossier and generate signed certificate."""
        dossier = self.get_object()

        if dossier.status not in [Dossier.Status.IN_REVIEW, Dossier.Status.APPROVED]:
            return error_response(
                message='Seul un dossier en vérification peut être approuvé.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        dossier.status = Dossier.Status.APPROVED
        dossier.completed_at = timezone.now()
        dossier.save(update_fields=['status', 'completed_at', 'updated_at'])

        # Génération du certificat PDF signé cryptographiquement
        from apps.dossiers.services.pdf_generator import generate_signed_certificate
        try:
            cert = generate_signed_certificate(dossier, officier=request.user)
            msg = (
                f'Dossier approuvé. Certificat {cert.dossier.reference} généré '
                f'avec signature HMAC et timbre {cert.timbre.reference}.'
            )
        except Exception as e:
            msg = f'Dossier approuvé, mais erreur lors de la génération du certificat : {str(e)}'

        return success_response(
            data=DossierDetailSerializer(dossier).data,
            message=msg,
        )

    @extend_schema(tags=['Dossiers'], summary='Rejeter un dossier', request=DossierRejectSerializer)
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsAgent | IsApprovalAgent | IsVerificationAgent | IsCivilAdmin | IsSuperAdmin])
    def reject(self, request, pk=None):
        """POST /api/dossiers/{id}/reject/ — Reject with reason."""
        dossier = self.get_object()
        serializer = DossierRejectSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if dossier.status != Dossier.Status.IN_REVIEW:
            return error_response(
                message='Seul un dossier en vérification peut être rejeté.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        dossier.status = Dossier.Status.REJECTED
        dossier.rejection_reason = serializer.validated_data['rejection_reason']
        dossier.completed_at = timezone.now()
        dossier.save(update_fields=['status', 'rejection_reason', 'completed_at', 'updated_at'])

        msg = 'Dossier rejeté.'
        
        if serializer.validated_data.get('requires_physical_presence', False):
            from apps.appointments.services import AppointmentService
            AppointmentService.create_appointment_for_rejection(dossier)
            msg = 'Dossier rejeté. Un rendez-vous a été créé pour une présence obligatoire.'

        return success_response(
            data=DossierDetailSerializer(dossier).data,
            message=msg,
        )

    @extend_schema(tags=['Dossiers'], summary='Terminer un dossier')
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsAgent | IsCivilAdmin])
    def complete(self, request, pk=None):
        """POST /api/dossiers/{id}/complete/ — Mark as completed."""
        dossier = self.get_object()

        if dossier.status != Dossier.Status.APPROVED:
            return error_response(
                message='Seul un dossier approuvé peut être marqué comme terminé.',
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        dossier.status = Dossier.Status.COMPLETED
        dossier.save(update_fields=['status', 'updated_at'])

        return success_response(
            data=DossierDetailSerializer(dossier).data,
            message='Dossier marqué comme terminé.',
        )

    @extend_schema(tags=['Dossiers'], summary='Télécharger le PDF')
    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated], url_path='download-pdf')
    def download_pdf(self, request, pk=None):
        """GET /api/dossiers/{id}/download-pdf/"""
        from django.http import FileResponse
        dossier = self.get_object()

        if dossier.type in ['regularisation', 'autorisation_construire', 'mutation_parcelle']:
            if dossier.status == Dossier.Status.DRAFT:
                return error_response(
                    message="Le récépissé n'est disponible qu'après soumission.",
                    status_code=status.HTTP_400_BAD_REQUEST
                )
        else:
            if dossier.status not in [Dossier.Status.APPROVED, Dossier.Status.COMPLETED]:
                return error_response(
                    message="Le document PDF n'est pas encore disponible.",
                    status_code=status.HTTP_400_BAD_REQUEST
                )

        from apps.documents.models import GeneratedCertificate
        try:
            cert = GeneratedCertificate.objects.get(dossier=dossier)
        except GeneratedCertificate.DoesNotExist:
            try:
                if dossier.type == 'regularisation':
                    from apps.dossiers.services.add_regularisation_receipt import generate_regularisation_receipt
                    cert = generate_regularisation_receipt(dossier)
                elif dossier.type == 'autorisation_construire':
                    from apps.dossiers.services.add_autorisation_receipt import generate_autorisation_receipt
                    cert = generate_autorisation_receipt(dossier)
                elif dossier.type == 'mutation_parcelle':
                    from apps.dossiers.services.add_mutation_receipt import generate_mutation_receipt
                    cert = generate_mutation_receipt(dossier)
                else:
                    from apps.dossiers.services.pdf_generator import generate_signed_certificate
                    cert = generate_signed_certificate(dossier, officier=request.user)
            except Exception as e:
                return error_response(
                    message=f"Erreur lors de la génération du PDF : {str(e)}",
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        if not cert.pdf_file:
            return error_response(message="Le fichier PDF est introuvable.", status_code=status.HTTP_404_NOT_FOUND)

        try:
            response = FileResponse(cert.pdf_file.open('rb'), content_type='application/pdf')
            response['Content-Disposition'] = f'inline; filename="Certificat_{dossier.reference}.pdf"'
            return response
        except Exception as e:
            return error_response(
                message=f"Erreur lors de la lecture du fichier : {str(e)}",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @extend_schema(tags=['Dossiers'], summary='Télécharger la Copie Littérale de Naissance')
    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated], url_path='download-copie-litterale')
    def download_copie_litterale(self, request, pk=None):
        """GET /api/dossiers/{id}/download-copie-litterale/"""
        from django.http import FileResponse
        import os
        from django.conf import settings
        dossier = self.get_object()

        if dossier.type != 'birth_certificate':
            return error_response(
                message="La copie littérale n'est disponible que pour les actes de naissance.",
                status_code=status.HTTP_400_BAD_REQUEST
            )

        if dossier.status not in [Dossier.Status.APPROVED, Dossier.Status.COMPLETED]:
            return error_response(
                message="Le dossier doit être approuvé ou terminé pour générer la copie littérale.",
                status_code=status.HTTP_400_BAD_REQUEST
            )

        # Récupération des cachets
        cachet_communal_path = ''
        signature_officier_path = ''
        cachet_nominal_path = ''

        if dossier.commune:
            if dossier.commune.chemin_cachet_communal:
                cachet_communal_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_cachet_communal)
            if dossier.commune.chemin_signature_officier:
                signature_officier_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_signature_officier)
            if dossier.commune.chemin_cachet_nominal:
                cachet_nominal_path = os.path.join(settings.BASE_DIR, dossier.commune.chemin_cachet_nominal)
            
            if not cachet_communal_path or not signature_officier_path or not cachet_nominal_path:
                from apps.dossiers.services.pdf_generator import get_seal_assets
                c_path, s_path, n_path = get_seal_assets(dossier.commune.name)
                cachet_communal_path = cachet_communal_path or c_path
                signature_officier_path = signature_officier_path or s_path
                cachet_nominal_path = cachet_nominal_path or n_path

        from apps.dossiers.services.pdf_generators.copie_litterale_naissance import generer_copie_litterale_naissance
        try:
            buffer = generer_copie_litterale_naissance(
                dossier, 
                officier=request.user, 
                cachet_path=cachet_communal_path, 
                signature_path=signature_officier_path, 
                cachet_nominal_path=cachet_nominal_path
            )
        except Exception as e:
            return error_response(
                message=f"Erreur lors de la génération de la copie littérale : {str(e)}",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        try:
            buffer.seek(0)
            response = FileResponse(buffer, content_type='application/pdf')
            response['Content-Disposition'] = f'inline; filename="Copie_Litterale_{dossier.reference}.pdf"'
            return response
        except Exception as e:
            return error_response(
                message=f"Erreur lors de la création de la réponse fichier : {str(e)}",
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    # =====================================================
    # COMMENTS
    # =====================================================

    @extend_schema(tags=['Dossiers'], summary='Commentaires du dossier')
    @action(detail=True, methods=['get', 'post'], permission_classes=[IsAuthenticated])
    def comments(self, request, pk=None):
        """GET/POST /api/dossiers/{id}/comments/"""
        dossier = self.get_object()

        if request.method == 'GET':
            comments = dossier.comments.select_related('author').all()
            serializer = DossierCommentSerializer(comments, many=True)
            return success_response(data=serializer.data)

        # POST
        serializer = DossierCommentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(dossier=dossier, author=request.user)
        return success_response(
            data=serializer.data,
            message='Commentaire ajouté.',
            status_code=status.HTTP_201_CREATED,
        )

