"""
Dashboard statistics views for TERANGA CIVIL.
"""
import csv
from django.http import StreamingHttpResponse
from collections import Counter
from datetime import timedelta

from django.db.models import (
    Count, Q, F, Avg, FloatField, DurationField, ExpressionWrapper
)
from django.db.models.functions import (
    TruncDay, TruncWeek, TruncMonth
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from drf_spectacular.utils import extend_schema

from apps.shared.permissions import IsAdminStaff
from apps.shared.responses import success_response
from apps.dossiers.models import Dossier
from apps.documents.models import Document


def format_duration(duration):
    """Format a timedelta into a human-readable duration string."""
    if duration is None:
        return '0s'
    total_seconds = int(duration.total_seconds())
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    if hours:
        return f'{hours}h {minutes}m'
    if minutes:
        return f'{minutes}m {seconds}s'
    return f'{seconds}s'


def get_base_queryset(user):
    qs = Dossier.objects.all()
    if user.role == 'super_admin':
        return qs
    elif user.role in ['civil_admin', 'civil_admin_supervisor']:
        if user.commune:
            return qs.filter(commune=user.commune)
        return qs.none()
    elif user.role == 'agent':
        return qs.filter(assigned_agent=user)
    return qs.none()

class DashboardStatsView(APIView):
    """API view for dashboard statistics."""

    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(
        tags=['Dashboard'],
        summary='Statistiques principales du dashboard'
    )
    def get(self, request):
        """Return global KPIs for the admin dashboard."""
        total_dossiers = get_base_queryset(request.user).count()
        total_documents = Document.objects.count()

        status_counts = {
            item['status']: item['count']
            for item in get_base_queryset(request.user).values(
                'status'
            ).annotate(count=Count('id'))
        }

        commune_counts = [
            {
                'commune': item['commune__name'] or 'Inconnue',
                'count': item['count'],
            }
            for item in get_base_queryset(request.user).values(
                'commune__name'
            ).annotate(
                count=Count('id')
            ).order_by('-count')
        ]

        document_type_counts = {
            item['file_type']: item['count']
            for item in Document.objects.values(
                'file_type'
            ).annotate(count=Count('id'))
        }

        from datetime import timedelta
        
        avg_review_query = get_base_queryset(request.user).exclude(
            submitted_at__isnull=True
        ).exclude(
            reviewed_at__isnull=True
        ).aggregate(
            avg_review=Avg(
                ExpressionWrapper(
                    F('reviewed_at') - F('submitted_at'),
                    output_field=DurationField()
                )
            )
        )

        avg_completion_query = get_base_queryset(request.user).exclude(
            submitted_at__isnull=True
        ).exclude(
            completed_at__isnull=True
        ).aggregate(
            avg_completion=Avg(
                ExpressionWrapper(
                    F('completed_at') - F('submitted_at'),
                    output_field=DurationField()
                )
            )
        )

        val_review = avg_review_query.get('avg_review') or 0
        average_review_time = val_review.total_seconds() if isinstance(val_review, timedelta) else val_review

        val_comp = avg_completion_query.get('avg_completion') or 0
        average_completion_time = val_comp.total_seconds() if isinstance(val_comp, timedelta) else val_comp

        # --- NOUVELLES STATISTIQUES ---
        total = total_dossiers
        dossiers_approuves = get_base_queryset(request.user).filter(status__in=[Dossier.Status.APPROVED, Dossier.Status.COMPLETED]).count()
        dossiers_rejetes = get_base_queryset(request.user).filter(status=Dossier.Status.REJECTED).count()
        total_traites = dossiers_approuves + dossiers_rejetes
        taux_approbation = round((dossiers_approuves / total_traites) * 100, 1) if total_traites > 0 else None

        dossiers_par_type_qs = get_base_queryset(request.user).values('type').annotate(count=Count('id'))
        dossiers_par_type = {item['type']: item['count'] for item in dossiers_par_type_qs}

        dossiers_par_commune_qs = get_base_queryset(request.user).values('commune__name').annotate(count=Count('id')).order_by('-count')[:5]
        dossiers_par_commune = [
            {'commune': item['commune__name'] or 'Inconnue', 'count': item['count']}
            for item in dossiers_par_commune_qs
        ]

        agents_actifs_qs = get_base_queryset(request.user).filter(assigned_agent__isnull=False).values('assigned_agent__first_name', 'assigned_agent__last_name').annotate(dossiers_traites=Count('id')).order_by('-dossiers_traites')[:3]
        agents_les_plus_actifs = [
            {'agent': f"{item['assigned_agent__first_name']} {item['assigned_agent__last_name']}".strip() or "Agent inconnu", 'dossiers_traites': item['dossiers_traites']}
            for item in agents_actifs_qs
        ]

        data = {
            'total_dossiers': total_dossiers,
            'total_documents': total_documents,
            'status_counts': status_counts,
            'dossiers_by_commune': commune_counts,
            'documents_by_type': document_type_counts,
            'average_review_time': format_duration(
                timedelta(seconds=average_review_time)
            ),
            'average_completion_time': format_duration(
                timedelta(seconds=average_completion_time)
            ),
            # Clés françaises (rétrocompat)
            'dossiers_par_type': dossiers_par_type,
            'dossiers_par_commune': dossiers_par_commune,
            'agents_les_plus_actifs': agents_les_plus_actifs,
            'taux_approbation': taux_approbation,
            # Clés anglaises (contrat API mobile / tests)
            'dossiers_by_type': dossiers_par_type,
            'top_agents': agents_les_plus_actifs,
        }

        return success_response(data=data)


class GlobalStatsView(APIView):
    """API for global statistics."""
    # Seuls les super admins et superviseurs peuvent voir les stats temporelles/globales avancées
    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(
        tags=['Dashboard'],
        summary='Statistiques globales'
    )
    def get(self, request):
        if request.user.role not in ['super_admin', 'civil_admin_supervisor']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Accès réservé aux superviseurs et super administrateurs.")
        stats = get_base_queryset(request.user).aggregate(
            total=Count('id'),
            en_cours=Count(
                'id',
                filter=Q(status__in=[
                    Dossier.Status.SUBMITTED,
                    Dossier.Status.IN_REVIEW
                ])
            ),
            valides=Count(
                'id',
                filter=Q(status=Dossier.Status.APPROVED)
            ),
            rejetes=Count(
                'id',
                filter=Q(status=Dossier.Status.REJECTED)
            )
        )
        total = stats['total']
        total_traites = stats['valides'] + stats['rejetes']
        taux = (
            round((stats['valides'] / total_traites * 100), 1)
            if total_traites and total_traites > 0 else None
        )

        return success_response({
            "total_dossiers": total,
            "dossiers_en_cours": stats['en_cours'],
            "dossiers_valides": stats['valides'],
            "dossiers_rejetes": stats['rejetes'],
            "taux_approbation": taux
        })


class PerformanceStatsView(APIView):
    """API for performance statistics."""
    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(
        tags=['Dashboard'],
        summary='Statistiques de performance'
    )
    def get(self, request):
        if request.user.role not in ['super_admin', 'civil_admin_supervisor']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Accès réservé aux superviseurs et super administrateurs.")
        time_diff = ExpressionWrapper(
            F('completed_at') - F('submitted_at'),
            output_field=DurationField()
        )
        avg_time_query = get_base_queryset(request.user).filter(
            status__in=[
                Dossier.Status.APPROVED,
            ],
            submitted_at__isnull=False,
            completed_at__isnull=False
        ).aggregate(temps_moyen=Avg(time_diff))

        perf_communes = get_base_queryset(request.user).values(
            'commune__name'
        ).annotate(
            total=Count('id')
        ).order_by('-total')[:10]

        perf_agents = get_base_queryset(request.user).filter(
            assigned_agent__isnull=False
        ).values(
            'assigned_agent__email'
        ).annotate(
            total=Count('id')
        ).order_by('-total')[:10]

        return success_response({
            "temps_moyen_traitement_secondes": (
                avg_time_query['temps_moyen'] or 0
            ),
            "performance_communes": list(perf_communes),
            "performance_agents": list(perf_agents)
        })


class ActivityStatsView(APIView):
    """API for activity statistics."""
    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(
        tags=['Dashboard'],
        summary="Statistiques d'activité"
    )
    def get(self, request):
        if request.user.role not in ['super_admin', 'civil_admin_supervisor']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Accès réservé aux superviseurs et super administrateurs.")
        daily = get_base_queryset(request.user).annotate(
            date=TruncDay('created_at')
        ).values('date').annotate(
            count=Count('id')
        ).order_by('-date')[:7]

        weekly = get_base_queryset(request.user).annotate(
            date=TruncWeek('created_at')
        ).values('date').annotate(
            count=Count('id')
        ).order_by('-date')[:4]

        monthly = get_base_queryset(request.user).annotate(
            date=TruncMonth('created_at')
        ).values('date').annotate(
            count=Count('id')
        ).order_by('-date')[:12]

        return success_response({
            "daily": list(daily),
            "weekly": list(weekly),
            "monthly": list(monthly)
        })


class ExportDossiersCSVView(APIView):
    """API view to export dossiers as CSV."""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Dashboard'],
        summary='Exporter les dossiers en CSV'
    )
    def get(self, request):
        user = request.user
        role = getattr(user, 'role', None)
        # Seuls les super_admin et civil_admin_supervisor peuvent exporter (comme demandé, export = stats avancées)
        if role not in ['super_admin', 'civil_admin_supervisor']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Accès refusé.")

        from datetime import datetime
        date_debut_str = request.query_params.get('date_debut')
        date_fin_str = request.query_params.get('date_fin')
        type_acte = request.query_params.get('type')
        status_dossier = request.query_params.get('status')
        agent_id = request.query_params.get('assigned_agent')

        queryset = get_base_queryset(request.user).select_related('citizen', 'commune', 'assigned_agent').all().order_by('-created_at')
        
        if type_acte:
            queryset = queryset.filter(type=type_acte)
        if status_dossier:
            queryset = queryset.filter(status=status_dossier)
        if agent_id:
            queryset = queryset.filter(assigned_agent_id=agent_id)

        if date_debut_str:
            try:
                date_debut = datetime.strptime(date_debut_str, '%Y-%m-%d').date()
                queryset = queryset.filter(submitted_at__gte=f"{date_debut}T00:00:00Z")
            except ValueError:
                from rest_framework.response import Response
                return Response({'error': 'Format date_debut invalide. Utiliser YYYY-MM-DD'}, status=400)
                
        if date_fin_str:
            try:
                date_fin = datetime.strptime(date_fin_str, '%Y-%m-%d').date()
                queryset = queryset.filter(submitted_at__lte=f"{date_fin}T23:59:59Z")
            except ValueError:
                from rest_framework.response import Response
                return Response({'error': 'Format date_fin invalide. Utiliser YYYY-MM-DD'}, status=400)
        
        if date_debut_str and date_fin_str:
            if date_debut > date_fin:
                from rest_framework.response import Response
                return Response({'error': 'date_debut ne peut pas être supérieure à date_fin'}, status=400)
        
        class Echo:
            def write(self, value):
                return value

        def iter_items():
            pseudo_buffer = Echo()
            writer = csv.DictWriter(
                pseudo_buffer,
                fieldnames=['reference', 'type', 'statut', 'citoyen', 'commune', 'agent_traitant', 'date_soumission', 'date_completion']
            )
            yield writer.writeheader()
            for dossier in queryset:
                citoyen_name = ""
                if dossier.citizen:
                    citoyen_name = f"{dossier.citizen.first_name} {dossier.citizen.last_name}".strip() or "Citoyen Inconnu"
                
                agent_name = ""
                if dossier.assigned_agent:
                    agent_name = f"{dossier.assigned_agent.first_name} {dossier.assigned_agent.last_name}".strip() or "Agent Inconnu"
                
                commune_name = dossier.commune.name if dossier.commune else ""
                
                date_soumission = dossier.submitted_at.strftime('%Y-%m-%d') if dossier.submitted_at else ""
                date_completion = dossier.completed_at.strftime('%Y-%m-%d') if dossier.completed_at else ""
                
                yield writer.writerow({
                    'reference': dossier.reference,
                    'type': dossier.type,
                    'statut': dossier.status,
                    'citoyen': citoyen_name,
                    'commune': commune_name,
                    'agent_traitant': agent_name,
                    'date_soumission': date_soumission,
                    'date_completion': date_completion
                })

        response = StreamingHttpResponse(iter_items(), content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="export_teranga_civil.csv"'
        return response


class WorkloadStatsView(APIView):
    """API for agent workload statistics (for civil_admin & civil_admin_supervisor)."""
    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(
        tags=['Dashboard'],
        summary='Charge de travail par agent'
    )
    def get(self, request):
        if request.user.role not in ['super_admin', 'civil_admin', 'civil_admin_supervisor']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Accès réservé aux administrateurs.")

        # Récupère tous les dossiers affectés à un agent dans la commune de l'admin
        qs = get_base_queryset(request.user).filter(assigned_agent__isnull=False)
        
        workload = qs.values(
            'assigned_agent__id',
            'assigned_agent__first_name',
            'assigned_agent__last_name'
        ).annotate(
            total_dossiers=Count('id'),
            en_cours=Count('id', filter=Q(status__in=[Dossier.Status.SUBMITTED, Dossier.Status.IN_REVIEW])),
            termines=Count('id', filter=Q(status__in=[Dossier.Status.APPROVED, Dossier.Status.REJECTED]))
        ).order_by('-en_cours')

        data = []
        for item in workload:
            data.append({
                'agent_id': item['assigned_agent__id'],
                'agent_name': f"{item['assigned_agent__first_name']} {item['assigned_agent__last_name']}".strip(),
                'total_dossiers': item['total_dossiers'],
                'dossiers_en_cours': item['en_cours'],
                'dossiers_termines': item['termines']
            })

        return success_response(data)
