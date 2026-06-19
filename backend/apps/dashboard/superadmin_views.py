from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count, Q, Sum
from datetime import timedelta
from django.utils import timezone
from django.utils.crypto import get_random_string
from django.db import transaction
from apps.shared.permissions import IsAdminStaff
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.communes.models import Commune
from apps.payments.models import PaymentTransaction
from apps.audit_logs.models import AuditLog

class SuperAdminPermission(IsAdminStaff):
    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.role == 'super_admin'

class SuperAdminOverviewView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        total_citizens = User.objects.filter(role='citizen').count()
        total_agents = User.objects.filter(role='agent', is_active=True).count()
        # Basic stats excluding test commune
        total_dossiers = Dossier.objects.exclude(commune__name__icontains='test').count()
        pending_dossiers = Dossier.objects.exclude(commune__name__icontains='test').filter(status__in=['pending', 'submitted', 'in_review']).count()
        approved_dossiers = Dossier.objects.exclude(commune__name__icontains='test').filter(status='approved').count()
        rejected_dossiers = Dossier.objects.exclude(commune__name__icontains='test').filter(status='rejected').count()
        
        # Payment stats excluding test commune
        payment_qs = PaymentTransaction.objects.exclude(dossier__commune__name__icontains='test').filter(status__in=['success', 'paid', 'completed'])
        total_revenue = payment_qs.aggregate(Sum('amount'))['amount__sum'] or 0
        total_count = payment_qs.count()
        
        # System stats
        active_communes = Commune.objects.exclude(name__icontains='test').filter(dossiers__isnull=False).distinct().count()
        
        return Response({
            'citizens': total_citizens,
            'agents': total_agents,
            'communes': active_communes,
            'dossiers': {
                'total': total_dossiers,
                'pending': pending_dossiers,
                'approved': approved_dossiers,
                'rejected': rejected_dossiers
            },
            'payments': {
                'count': total_count,
                'revenue': total_revenue
            }
        })

class SuperAdminPassationView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def post(self, request):
        new_super_admin_id = request.data.get('new_super_admin_id')
        if not new_super_admin_id:
            return Response({'error': 'ID du nouveau Super Admin requis'}, status=400)
            
        try:
            new_sa = User.objects.get(id=new_super_admin_id)
            if new_sa.role != 'super_admin':
                new_sa.role = 'super_admin'
                new_sa.save()
            
            # Optionally demote current user
            current_user = request.user
            current_user.is_active = False # Or change role
            current_user.save()
            
            AuditLog.log(
                user=current_user,
                action=AuditLog.Action.ROLE_CHANGE,
                resource_type='user',
                resource_id=new_sa.id,
                details={'message': f'Passation de service vers {new_sa.email}'}
            )
            return Response({'message': 'Passation de service réussie.'})
        except User.DoesNotExist:
            return Response({'error': 'Utilisateur introuvable'}, status=404)

class CommunePerformanceView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        communes = Commune.objects.exclude(name__icontains='test').annotate(
            total_dossiers=Count('dossiers'),
            approved_dossiers=Count('dossiers', filter=Q(dossiers__status='approved')),
            rejected_dossiers=Count('dossiers', filter=Q(dossiers__status='rejected')),
            revenue=Sum('dossiers__payments__amount', filter=Q(dossiers__payments__status__in=['success', 'paid', 'completed']))
        ).order_by('-total_dossiers')
        
        data = []
        for c in communes:
            data.append({
                'id': c.id,
                'name': c.name,
                'region': c.region,
                'total_dossiers': c.total_dossiers,
                'approved_dossiers': c.approved_dossiers,
                'rejected_dossiers': c.rejected_dossiers,
                'revenue': c.revenue or 0,
            })
            
        return Response(data)

from datetime import timedelta
from django.utils import timezone
from django.db.models.functions import TruncDay, TruncWeek, TruncMonth

class SuperAdminChartsView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        period = request.GET.get('period', '30d')
        now = timezone.now()
        
        if period == '7d':
            start_date = now - timedelta(days=7)
            trunc_func = TruncDay('created_at')
        elif period == '30d':
            start_date = now - timedelta(days=30)
            trunc_func = TruncDay('created_at')
        elif period == '6m':
            start_date = now - timedelta(days=180)
            trunc_func = TruncWeek('created_at')
        elif period == '1y':
            start_date = now - timedelta(days=365)
            trunc_func = TruncMonth('created_at')
        else:
            start_date = now - timedelta(days=30)
            trunc_func = TruncDay('created_at')
            
        docs_breakdown = Dossier.objects.exclude(commune__name__icontains='test').values('type').annotate(count=Count('id'))
        
        dossiers_trend = Dossier.objects.exclude(commune__name__icontains='test').filter(created_at__gte=start_date)\
            .annotate(date=trunc_func)\
            .values('date')\
            .annotate(
                total=Count('id'),
                approved=Count('id', filter=Q(status='approved')),
                pending=Count('id', filter=Q(status__in=['pending', 'submitted', 'in_review']))
            ).order_by('date')

        # Restored for SuperStatistics
        from django.db.models.functions import TruncMonth
        revenue_trend = PaymentTransaction.objects.exclude(dossier__commune__name__icontains='test')\
            .filter(status__in=['success', 'paid', 'completed'])\
            .annotate(month=TruncMonth('created_at'))\
            .values('month')\
            .annotate(revenue=Sum('amount'))\
            .order_by('month')
            
        return Response({
            'documents_breakdown': docs_breakdown,
            'dossiers_trend': dossiers_trend,
            'revenue_trend': revenue_trend
        })

class SuperAdminAlertsView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        alerts = []
        now = timezone.now()
        
        # 1. Rejets anormaux
        total_dossiers = Dossier.objects.exclude(commune__name__icontains='test').count()
        total_rejected = Dossier.objects.exclude(commune__name__icontains='test').filter(status='rejected').count()
        national_rejection_rate = (total_rejected / total_dossiers) if total_dossiers > 0 else 0
        
        if national_rejection_rate > 0:
            communes = Commune.objects.exclude(name__icontains='test').annotate(
                total=Count('dossiers'),
                rejected=Count('dossiers', filter=Q(dossiers__status='rejected'))
            )
            for c in communes:
                if c.total > 5: # Ignorer les communes avec très peu de dossiers
                    rejection_rate = c.rejected / c.total
                    if rejection_rate > (national_rejection_rate * 2):
                        alerts.append({
                            'id': f'rejet-{c.id}',
                            'type': 'error',
                            'title': f'Taux de rejet élevé à {c.name}',
                            'message': f"Le taux de rejet ({int(rejection_rate*100)}%) est plus du double de la moyenne nationale.",
                            'link': '/super/communes'
                        })
        
        # 2. Dossiers en retard
        seven_days_ago = now - timedelta(days=7)
        delayed_dossiers = Dossier.objects.exclude(commune__name__icontains='test').filter(
            status__in=['submitted', 'in_review'], 
            created_at__lte=seven_days_ago
        ).values('commune__name').annotate(count=Count('id'))
        
        for d in delayed_dossiers:
            if d['count'] > 0:
                alerts.append({
                    'id': f"retard-{d['commune__name']}",
                    'type': 'warning',
                    'title': f"{d['count']} dossiers en attente depuis plus de 7 jours à {d['commune__name']}",
                    'message': "Dossiers bloqués à traiter rapidement.",
                    'link': '/super/dossiers'
                })
                
        # 3. Agents inactifs
        fourteen_days_ago = now - timedelta(days=14)
        inactive_agents = User.objects.exclude(commune__name__icontains='test').filter(
            role__in=['civil_admin_supervisor', 'civil_agent'],
            last_login__lte=fourteen_days_ago
        ).select_related('commune')
        
        for agent in inactive_agents:
            days_inactive = (now - agent.last_login).days
            commune_name = agent.commune.name if agent.commune else 'Sans commune'
            alerts.append({
                'id': f'inactif-{agent.id}',
                'type': 'info',
                'title': f"Agent inactif depuis {days_inactive} jours à {commune_name}",
                'message': f"L'agent {agent.get_full_name()} ne s'est pas connecté récemment.",
                'link': '/super/users'
            })
            
        return Response(alerts)

class SystemActivityView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        now = timezone.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        
        last_logins = User.objects.filter(last_login__isnull=False).order_by('-last_login')[:10].values('first_name', 'last_name', 'role', 'last_login', 'commune__name')
        actions_today = AuditLog.objects.filter(created_at__gte=today_start).count()
        active_users_today = AuditLog.objects.filter(created_at__gte=today_start).values('user').distinct().count()
        
        alerts = []
        seven_days_ago = now - timedelta(days=7)
        old_pending = Dossier.objects.exclude(commune__name__icontains='test').filter(status='pending', created_at__lte=seven_days_ago).count()
        if old_pending > 0:
            alerts.append({
                'type': 'warning',
                'message': f"{old_pending} dossiers en attente depuis plus de 7 jours."
            })
            
        return Response({
            'last_logins': last_logins,
            'actions_today': actions_today,
            'active_users_today': active_users_today,
            'alerts': alerts
        })

class AuditSecurityView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        logs = AuditLog.objects.all()[:100]
        data = []
        for l in logs:
            data.append({
                'id': l.id,
                'action': l.action,
                'user': l.user.email if l.user else 'Système',
                'user_type': l.user_type,
                'status': l.status,
                'resource_type': l.resource_type,
                'created_at': l.created_at,
                'ip_address': l.ip_address
            })
        return Response(data)

class SuperAdminCommuneManagerView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    def get(self, request):
        communes = Commune.objects.all().prefetch_related('users')
        data = []
        for c in communes:
            admins = c.users.filter(role__in=['civil_admin', 'civil_admin_supervisor']).values(
                'id', 'first_name', 'last_name', 'email', 'role', 'is_active'
            )
            
            # Déterminer si la commune est active (on considère qu'elle est active si au moins un de ses admins l'est, ou par défaut True si c'est une nouvelle logique, mais ici on peut juste envoyer l'état des admins)
            is_active = any(a['is_active'] for a in admins) if admins else True

            data.append({
                'id': c.id,
                'name': c.name,
                'region': c.region,
                'department': c.department,
                'code': c.code,
                'is_active': is_active,
                'admins': list(admins)
            })
        return Response(data)

    @transaction.atomic
    def post(self, request):
        data = request.data
        
        # 1. Infos Commune
        c_name = data.get('name')
        c_region = data.get('region')
        c_dept = data.get('department')
        c_address = data.get('address', '')
        c_phone = data.get('phone', '')
        
        # 2. Infos Admins
        admin_general = data.get('admin_general')
        admin_rh = data.get('admin_rh')
        
        if not (c_name and c_region and c_dept and admin_general and admin_rh):
            return Response({'error': 'Informations incomplètes'}, status=400)
            
        # Génération du code commune
        base_code = f"{c_region[:3].upper()}-{c_dept[:3].upper()}"
        existing_count = Commune.objects.filter(code__startswith=base_code).count()
        c_code = f"{base_code}-{existing_count + 1:03d}"

        commune = Commune.objects.create(
            name=c_name,
            region=c_region,
            department=c_dept,
            address=c_address,
            phone=c_phone,
            code=c_code,
            nom_commune_officiel=f"Commune de {c_name}"
        )
        
        # Création des comptes
        credentials = []
        
        for role_key, role_val in [('admin_general', 'civil_admin_supervisor'), ('admin_rh', 'civil_admin')]:
            info = data.get(role_key)
            if info:
                email = info.get('email')
                first_name = info.get('first_name', '')
                last_name = info.get('last_name', '')
                
                if User.objects.filter(email=email).exists():
                    return Response({'error': f"L'email {email} est déjà utilisé."}, status=400)
                    
                temp_password = get_random_string(12)
                
                user = User.objects.create_user(
                    email=email,
                    password=temp_password,
                    first_name=first_name,
                    last_name=last_name,
                    role=role_val,
                    commune=commune,
                    must_change_password=True
                )
                
                credentials.append({
                    'role_label': 'Admin Général' if role_key == 'admin_general' else 'Admin RH',
                    'email': email,
                    'temp_password': temp_password
                })
                
        return Response({
            'message': 'Mairie et comptes créés avec succès',
            'commune': {'id': commune.id, 'name': commune.name},
            'credentials': credentials
        })

class SuperAdminCommuneToggleView(APIView):
    permission_classes = [IsAuthenticated, SuperAdminPermission]

    @transaction.atomic
    def patch(self, request, pk):
        try:
            commune = Commune.objects.get(id=pk)
            # On cherche l'état actuel : si tous les admins sont inactifs, on réactive. Sinon on désactive tout le monde.
            admins = commune.users.filter(role__in=['civil_admin', 'civil_admin_supervisor'])
            
            currently_active = admins.filter(is_active=True).exists()
            new_status = not currently_active
            
            admins.update(is_active=new_status)
            # On pourrait aussi désactiver les agents simples si on le souhaite :
            commune.users.filter(role='agent').update(is_active=new_status)
            
            return Response({'message': f"Commune {'activée' if new_status else 'désactivée'} avec succès.", 'is_active': new_status})
        except Commune.DoesNotExist:
            return Response({'error': 'Commune introuvable'}, status=404)
