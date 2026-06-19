"""
Services views — API endpoints pour Paiements, Signalements, Sondages.

Architecture :
    - ViewSets avec mixins pour un contrôle fin des opérations autorisées
    - Permissions RBAC (citizen, admin, super_admin)
    - Intégration avec les mocks de paiement (swap transparent en production)
"""
import logging
from django.db import transaction as db_transaction
from django.db.models import F
from django.utils import timezone
from rest_framework import viewsets, status, mixins
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from drf_spectacular.utils import extend_schema, extend_schema_view

from apps.shared.permissions import IsCitizen, IsAdminStaff
from apps.shared.responses import success_response, error_response
from apps.integrations.payment_mock import PaymentGatewayMock

from .models import Transaction, Report, Survey, SurveyOption, SurveyVote
from .serializers import (
    TransactionSerializer,
    ReportSerializer,
    ReportAdminUpdateSerializer,
    SurveySerializer,
    SurveyVoteSerializer,
)

logger = logging.getLogger('system')


# =============================================================================
# PAIEMENTS
# =============================================================================

@extend_schema_view(
    list=extend_schema(tags=['Services - Paiements'], summary='Lister les transactions'),
    retrieve=extend_schema(tags=['Services - Paiements'], summary='Détail d\'une transaction'),
    create=extend_schema(tags=['Services - Paiements'], summary='Initier un paiement'),
)
class TransactionViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """Gestion des transactions de paiement pour les dossiers."""
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Transaction.objects.select_related('citizen', 'dossier')
        if user.role == 'citizen':
            return qs.filter(citizen=user)
        return qs.all()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        transaction = serializer.save()

        # Initier le paiement via le mock
        payment_mock = PaymentGatewayMock()
        payment_response = payment_mock.initiate_payment(
            amount=transaction.amount,
            phone_number=transaction.phone_number,
            provider=transaction.provider,
        )

        if not payment_response.get('success'):
            # Si l'initiation échoue, marquer comme failed
            transaction.status = Transaction.Status.FAILED
            transaction.metadata = {'error': payment_response.get('error', 'Erreur inconnue')}
            transaction.save()
            return error_response(
                message=payment_response.get('error', 'Erreur lors de l\'initiation du paiement.'),
                status_code=400,
            )

        transaction.external_transaction_id = payment_response.get('transaction_id', '')
        transaction.metadata = {
            'payment_url': payment_response.get('payment_url', ''),
            'fees': payment_response.get('fees', '0'),
        }
        transaction.save()

        logger.info(
            f'[Payment] Transaction {transaction.reference} initiée '
            f'par {request.user.email} — {transaction.amount} FCFA via {transaction.provider}.'
        )

        return success_response(
            data=TransactionSerializer(transaction).data,
            message='Paiement initié.',
            status_code=status.HTTP_201_CREATED,
        )

    @extend_schema(tags=['Services - Paiements'], summary='Vérifier le statut du paiement')
    @action(detail=True, methods=['post'])
    def check_status(self, request, pk=None):
        """Vérifie le statut d'une transaction auprès de l'opérateur."""
        txn = self.get_object()

        if txn.status not in (Transaction.Status.PENDING, Transaction.Status.PROCESSING):
            return success_response(
                data=TransactionSerializer(txn).data,
                message=f'Transaction déjà finalisée ({txn.get_status_display()}).',
            )

        payment_mock = PaymentGatewayMock()
        status_response = payment_mock.check_transaction_status(txn.external_transaction_id)

        if status_response.get('status') == 'completed':
            txn.status = Transaction.Status.COMPLETED
            txn.paid_at = timezone.now()
            txn.receipt_url = f"https://receipts.sunu-civil.sn/{status_response.get('receipt_number', '')}"
            txn.save()

            logger.info(f'[Payment] Transaction {txn.reference} confirmée.')

        return success_response(data=TransactionSerializer(txn).data)


# =============================================================================
# SIGNALEMENTS CITOYENS
# =============================================================================

@extend_schema_view(
    list=extend_schema(tags=['Services - Signalements'], summary='Lister les signalements'),
    retrieve=extend_schema(tags=['Services - Signalements'], summary='Détail d\'un signalement'),
    create=extend_schema(tags=['Services - Signalements'], summary='Créer un signalement'),
)
class ReportViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """Signalements citoyens (voirie, déchets, éclairage, etc.)."""
    serializer_class = ReportSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Report.objects.select_related('citizen', 'commune')
        if user.role == 'citizen':
            return qs.filter(citizen=user)
        elif hasattr(user, 'is_admin_staff') and user.is_admin_staff and user.commune:
            return qs.filter(commune=user.commune)
        elif user.role == 'super_admin':
            return qs.all()
        return Report.objects.none()

    @extend_schema(
        tags=['Services - Signalements'],
        summary='Mettre à jour le statut du signalement',
        request=ReportAdminUpdateSerializer,
    )
    @action(detail=True, methods=['patch'], permission_classes=[IsAuthenticated, IsAdminStaff])
    def update_status(self, request, pk=None):
        """Permet à un admin de mettre à jour le statut et les notes d'un signalement."""
        report = self.get_object()
        serializer = ReportAdminUpdateSerializer(report, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        logger.info(
            f'[Report] Signalement #{report.id} mis à jour par {request.user.email} '
            f'→ statut : {report.get_status_display()}.'
        )

        return success_response(
            data=ReportSerializer(report).data,
            message='Signalement mis à jour.',
        )


# =============================================================================
# SONDAGES & PARTICIPATION CITOYENNE
# =============================================================================

@extend_schema_view(
    list=extend_schema(tags=['Services - Sondages'], summary='Lister les sondages'),
    retrieve=extend_schema(tags=['Services - Sondages'], summary='Détail d\'un sondage'),
)
class SurveyViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """Sondages et consultations citoyennes."""
    serializer_class = SurveySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Survey.objects.select_related('commune', 'created_by').prefetch_related('options')
        if hasattr(user, 'is_admin_staff') and user.is_admin_staff and user.commune:
            return qs.filter(commune=user.commune)
        elif user.role == 'citizen' and user.commune:
            return qs.filter(commune=user.commune)
        return qs.all()

    @extend_schema(
        tags=['Services - Sondages'],
        summary='Voter à un sondage',
        request=SurveyVoteSerializer,
    )
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsCitizen])
    def vote(self, request, pk=None):
        """Permet à un citoyen de voter pour une option d'un sondage."""
        survey = self.get_object()
        data = request.data.copy()
        data['survey'] = survey.id

        serializer = SurveyVoteSerializer(data=data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        option = serializer.validated_data['option']

        # Transaction atomique + F() pour éviter les race conditions
        with db_transaction.atomic():
            SurveyVote.objects.create(
                survey=survey,
                option=option,
                citizen=request.user,
            )
            SurveyOption.objects.filter(pk=option.pk).update(
                votes_count=F('votes_count') + 1,
            )

        logger.info(
            f'[Survey] Vote enregistré — Sondage "{survey.title}", '
            f'option "{option.text}" par {request.user.email}.'
        )

        return success_response(message='Votre vote a été enregistré.')
