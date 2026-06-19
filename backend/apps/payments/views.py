from rest_framework.generics import ListAPIView
from rest_framework.permissions import IsAuthenticated
from apps.shared.responses import error_response
from .models import PaymentTransaction
from .serializers import PaymentTransactionSerializer
from drf_spectacular.utils import extend_schema
from rest_framework.views import APIView
from apps.shared.responses import success_response

class IsSuperAdmin(IsAuthenticated):
    def has_permission(self, request, view):
        is_authenticated = super().has_permission(request, view)
        return is_authenticated and hasattr(request.user, 'role') and request.user.role == 'super_admin'

class InitiatePaymentView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        from django.utils.crypto import get_random_string
        from apps.dossiers.models import Dossier
        
        # Récupérer les données envoyées par le mobile
        dossier_id = request.data.get('dossier_id')
        method = request.data.get('method', 'wave')
        phone = request.data.get('phone', 'N/A')
        
        AMOUNT_MAPPING = {
            Dossier.Type.BIRTH_CERTIFICATE: 500.00,
            Dossier.Type.DEATH_CERTIFICATE: 500.00,
            Dossier.Type.MARRIAGE_CERTIFICATE: 1000.00,
            Dossier.Type.RESIDENCE_CERTIFICATE: 500.00,
            Dossier.Type.REGULARISATION: 500.00,
            Dossier.Type.OTHER: 500.00,
        }
        
        amount = 500.00
        dossier = None
        if dossier_id:
            try:
                dossier = Dossier.objects.get(id=dossier_id)
                amount = AMOUNT_MAPPING.get(dossier.type, 500.00)
            except Dossier.DoesNotExist:
                pass
        
        # Simuler la création d'une vraie transaction en base de données
        tx = PaymentTransaction.objects.create(
            reference=f"TX_{get_random_string(8).upper()}",
            amount=amount,
            currency='XOF',
            payment_type=method,
            status='success', # On force le succès pour la simulation
            payer_name=request.user.full_name if hasattr(request.user, 'full_name') else "Citoyen",
            payer_id=phone,
            service_label=f"Frais de traitement - Dossier {str(dossier_id)[:8] if dossier_id else 'Inconnu'}",
            dossier=dossier,
        )
        
        # Mise à jour du statut du dossier à 'soumis' (payé)
        if dossier:
            dossier.status = Dossier.Status.SUBMITTED
            from django.utils import timezone
            dossier.submitted_at = timezone.now()
            dossier.save(update_fields=['status', 'submitted_at'])
            
            # --- Envoi du signal Temps Réel (WebSockets) ---
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync
            from apps.dossiers.serializers import DossierDetailSerializer
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                'admin_dashboard',
                {
                    'type': 'dashboard_update',
                    'message': 'new_dossier',
                    'data': DossierDetailSerializer(dossier).data
                }
            )
        
        # Réponse attendue par le mobile
        return success_response(
            message="Paiement simulé avec succès.",
            data={"status": "success", "transaction_id": str(tx.reference)}
        )

from apps.shared.permissions import IsSuperAdmin, IsCivilAdminSupervisor

class AdminTransactionListView(ListAPIView):
    """
    GET /api/v1/admin/transactions
    Permet au super administrateur ou superviseur de lister les transactions de paiement.
    """
    serializer_class = PaymentTransactionSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin | IsCivilAdminSupervisor]

    def get_queryset(self):
        queryset = PaymentTransaction.objects.all().select_related('dossier', 'agent').prefetch_related('treasury_transfers')
        
        if self.request.user.role == 'civil_admin_supervisor' and self.request.user.commune:
            queryset = queryset.filter(dossier__commune=self.request.user.commune)

        # Filtre par type de paiement
        payment_type = self.request.query_params.get('payment_type')
        if payment_type:
            queryset = queryset.filter(payment_type=payment_type)

        # Filtre par statut
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)

        # Filtre par date de début (YYYY-MM-DD)
        date_from = self.request.query_params.get('date_from')
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)

        # Filtre par date de fin (YYYY-MM-DD)
        date_to = self.request.query_params.get('date_to')
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)

        return queryset

    @extend_schema(
        tags=['Paiements'],
        summary='Liste des transactions de paiement',
        description='Récupère les transactions de paiement filtrées pour le rôle Super Admin.'
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

from django.db.models import Sum, Count
from django.utils import timezone
from .models import PaymentStatus

class AdminTransactionStatsView(APIView):
    """
    GET /api/v1/admin/transactions/stats
    Permet de récupérer les statistiques globales des transactions.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin | IsCivilAdminSupervisor]

    @extend_schema(
        tags=['Paiements'],
        summary='Statistiques des transactions de paiement',
        description='Calcule le total par jour, le montant total, le taux de succès et la répartition par type.'
    )
    def get(self, request, *args, **kwargs):
        now = timezone.now()
        today = now.date()
        
        qs = PaymentTransaction.objects.all()
        if request.user.role == 'civil_admin_supervisor' and request.user.commune:
            qs = qs.filter(dossier__commune=request.user.commune)

        # Nombre total de transactions créées aujourd'hui
        total_today = qs.filter(created_at__date=today).count()

        # Montant total cumulé de toutes les transactions réussies
        total_amount = qs.filter(status=PaymentStatus.SUCCESS).aggregate(total=Sum('amount'))['total'] or 0.0

        # Taux de succès global
        total_count = qs.count()
        success_count = qs.filter(status=PaymentStatus.SUCCESS).count()
        success_rate = (success_count / total_count * 100) if total_count > 0 else 0.0

        # Répartition par type de paiement
        distribution = list(
            qs.values('payment_type')
            .annotate(count=Count('id'))
            .order_by('-count')
        )
        dist_dict = {item['payment_type']: item['count'] for item in distribution}

        return success_response({
            'total_today': total_today,
            'total_amount': float(total_amount),
            'success_rate': round(success_rate, 2),
            'distribution': dist_dict
        })


from django.utils.crypto import get_random_string
from django.utils import timezone
from django.http import HttpResponse
from apps.dossiers.models import Dossier
from apps.audit_logs.models import AuditLog
from .services import generate_receipt_pdf

class RegisterGuichetPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if not hasattr(user, 'role') or user.role not in ['agent', 'civil_admin', 'super_admin']:
            return error_response(message="Vous n'avez pas l'autorisation d'enregistrer des paiements.", status_code=403)

        dossier_id = request.data.get('dossier_id')
        amount = request.data.get('amount')
        payment_type = request.data.get('payment_type')
        transaction_reference = request.data.get('transaction_reference', '')
        comment = request.data.get('comment', '')

        if not dossier_id or amount is None or not payment_type:
            return error_response(message="Champs requis manquants: dossier_id, amount, payment_type.", status_code=400)

        try:
            dossier = Dossier.objects.get(id=dossier_id)
        except Dossier.DoesNotExist:
            return error_response(message="Dossier introuvable.", status_code=404)

        # Validation du montant
        AMOUNT_MAPPING = {
            Dossier.Type.BIRTH_CERTIFICATE: 500.00,
            Dossier.Type.DEATH_CERTIFICATE: 500.00,
            Dossier.Type.MARRIAGE_CERTIFICATE: 1000.00,
            Dossier.Type.RESIDENCE_CERTIFICATE: 500.00,
            Dossier.Type.REGULARISATION: 500.00,
            Dossier.Type.OTHER: 500.00,
        }
        expected_amount = AMOUNT_MAPPING.get(dossier.type, 500.00)
        if float(amount) < expected_amount:
            return error_response(message=f"Le montant minimum pour ce type de dossier est de {expected_amount} XOF.", status_code=400)

        if payment_type in ['wave', 'orange_money', 'free_money'] and not transaction_reference:
            return error_response(message=f"La référence de transaction est obligatoire pour le mode de paiement {payment_type}.", status_code=400)

        payer_name = "Citoyen Anonyme"
        payer_id = "N/A"
        if dossier.citizen:
            payer_name = dossier.citizen.full_name
            payer_id = dossier.citizen.phone or dossier.citizen.email or dossier.citizen.username
        elif dossier.citoyen_guichet:
            payer_name = dossier.citoyen_guichet.nom_complet
            payer_id = dossier.citoyen_guichet.telephone or dossier.citoyen_guichet.cni or "N/A"

        import random
        today_str = timezone.now().strftime('%Y%m%d')
        while True:
            rand_part = "".join([str(random.randint(0, 9)) for _ in range(4)])
            receipt_number = f"REC-{today_str}-{rand_part}"
            if not PaymentTransaction.objects.filter(receipt_number=receipt_number).exists():
                break

        tx = PaymentTransaction.objects.create(
            reference=f"TX_{get_random_string(8).upper()}",
            amount=amount,
            currency='XOF',
            payment_type=payment_type,
            status='paid',
            payer_name=payer_name,
            payer_id=payer_id,
            service_label=f"Frais de traitement: {dossier.get_type_display()}",
            dossier=dossier,
            agent=user,
            receipt_number=receipt_number,
            transaction_reference=transaction_reference,
            comment=comment
        )

        dossier.status = Dossier.Status.SUBMITTED
        dossier.submitted_at = timezone.now()
        dossier.save(update_fields=['status', 'submitted_at'])

        AuditLog.log(
            user=user,
            action=AuditLog.Action.CREATE,
            resource_type='payment_transaction',
            resource_id=tx.id,
            details={
                'dossier_id': str(dossier.id),
                'receipt_number': receipt_number,
                'amount': float(amount),
                'payment_type': payment_type
            }
        )

        try:
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync
            from apps.dossiers.serializers import DossierDetailSerializer
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                'admin_dashboard',
                {
                    'type': 'dashboard_update',
                    'message': 'new_dossier',
                    'data': DossierDetailSerializer(dossier).data
                }
            )
            async_to_sync(channel_layer.group_send)(
                'admin_dashboard',
                {
                    'type': 'dashboard_update',
                    'message': 'new_transaction',
                    'data': PaymentTransactionSerializer(tx).data
                }
            )
        except Exception as e:
            pass

        return success_response(
            message="Paiement enregistré avec succès.",
            data={
                "status": "success",
                "transaction_id": str(tx.id),
                "receipt_number": receipt_number,
                "pdf_url": f"/api/transactions/{tx.id}/receipt/"
            }
        )


class DownloadReceiptPDFView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            tx = PaymentTransaction.objects.get(id=pk)
        except PaymentTransaction.DoesNotExist:
            return HttpResponse("Transaction introuvable.", status=404)

        pdf_data = generate_receipt_pdf(tx)

        AuditLog.log(
            user=request.user,
            action=AuditLog.Action.DOWNLOAD,
            resource_type='payment_receipt',
            resource_id=tx.id,
            details={'receipt_number': tx.receipt_number}
        )

        response = HttpResponse(pdf_data, content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="recu_{tx.receipt_number or tx.reference}.pdf"'
        return response


