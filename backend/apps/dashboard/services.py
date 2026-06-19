"""
Dashboard services — Logique métier avec système de Cache intégral.

Architecture :
    - Chaque méthode utilise le cache Django (Redis/Memcached/local)
    - Invalidation automatique via le signal `post_save` sur Dossier
    - Requêtes optimisées avec `annotate()` (zéro N+1 query)
"""
import logging
from datetime import timedelta
from django.db.models import (
    Count, Avg, Min, Max, Q, F,
    ExpressionWrapper, DurationField, Subquery, OuterRef,
)
from django.db.models.functions import TruncDate, Coalesce
from django.utils import timezone
from django.core.cache import cache
from django.contrib.auth import get_user_model
from apps.dossiers.models import Dossier

logger = logging.getLogger('system')
User = get_user_model()

# ── Durées de cache (en secondes) ──
CACHE_TTL_SHORT = 120    # 2 minutes — données très dynamiques
CACHE_TTL_MEDIUM = 300   # 5 minutes — dashboard overview
CACHE_TTL_LONG = 600     # 10 minutes — données moins volatiles

# ── Préfixe commun pour l'invalidation groupée ──
CACHE_PREFIX = 'dash'


def _cache_key(name, commune=None, **extras):
    """Génère une clé de cache déterministe et unique."""
    parts = [CACHE_PREFIX, name]
    parts.append(str(commune.id) if commune else 'global')
    for k, v in sorted(extras.items()):
        parts.append(f'{k}_{v}')
    return ':'.join(parts)


def invalidate_dashboard_cache():
    """
    Invalide tout le cache dashboard.
    Appelé automatiquement quand un Dossier est créé/modifié (via signals).
    Compatible avec tous les backends de cache Django.
    """
    # Pour les backends qui supportent les patterns (Redis)
    try:
        if hasattr(cache, 'delete_pattern'):
            cache.delete_pattern(f'{CACHE_PREFIX}:*')
            logger.info('[Dashboard] Cache invalidé via pattern.')
            return
    except Exception:
        pass

    # Fallback : on supprime les clés connues
    known_keys = cache.get(f'{CACHE_PREFIX}:_keys', set())
    if known_keys:
        cache.delete_many(list(known_keys))
        cache.delete(f'{CACHE_PREFIX}:_keys')
        logger.info(f'[Dashboard] Cache invalidé ({len(known_keys)} clés supprimées).')


def _cache_set(key, data, ttl):
    """Set cache + enregistre la clé pour l'invalidation."""
    cache.set(key, data, ttl)
    # Maintenir un registre des clés pour le fallback d'invalidation
    known_keys = cache.get(f'{CACHE_PREFIX}:_keys', set())
    known_keys.add(key)
    cache.set(f'{CACHE_PREFIX}:_keys', known_keys, CACHE_TTL_LONG * 10)


class DashboardStatsService:
    """
    Service centralisé pour les statistiques du dashboard.

    Principes d'optimisation :
        1. Cache systématique sur chaque endpoint
        2. Agrégations côté DB (zéro boucle Python sur les querysets)
        3. `select_related` / `prefetch_related` sur les FK
        4. Clés de cache déterministes avec invalidation automatique
    """

    # ── VUE D'ENSEMBLE ──

    @staticmethod
    def get_overview(commune=None):
        """Statistiques globales avec cache."""
        cache_key = _cache_key('overview', commune)
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        qs = Dossier.objects.all()
        if commune:
            qs = qs.filter(commune=commune)

        total = qs.count()
        completed = qs.filter(status=Dossier.Status.COMPLETED).count()

        # Temps de traitement moyen (une seule requête agrégée)
        avg_delta = qs.filter(
            submitted_at__isnull=False,
            completed_at__isnull=False,
        ).annotate(
            processing_time=ExpressionWrapper(
                F('completed_at') - F('submitted_at'),
                output_field=DurationField(),
            )
        ).aggregate(avg=Avg('processing_time'))['avg']

        # Filtres pour les compteurs d'utilisateurs
        user_filter = {'commune': commune} if commune else {}

        data = {
            'total_dossiers': total,
            'total_pending': qs.filter(status=Dossier.Status.SUBMITTED).count(),
            'total_in_review': qs.filter(status=Dossier.Status.IN_REVIEW).count(),
            'total_approved': qs.filter(status=Dossier.Status.APPROVED).count(),
            'total_rejected': qs.filter(status=Dossier.Status.REJECTED).count(),
            'total_completed': completed,
            'total_citizens': User.objects.filter(role='citizen', **user_filter).count(),
            'total_agents': User.objects.exclude(role='citizen').filter(**user_filter).count(),
            'avg_processing_hours': round(avg_delta.total_seconds() / 3600, 2) if avg_delta else None,
            'completion_rate': round((completed / total) * 100, 2) if total > 0 else 0.0,
        }

        _cache_set(cache_key, data, CACHE_TTL_MEDIUM)
        return data

    # ── RÉPARTITIONS ──

    @staticmethod
    def get_count_by_status(commune=None):
        """Nombre de dossiers par statut avec cache."""
        cache_key = _cache_key('by_status', commune)
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        qs = Dossier.objects.all()
        if commune:
            qs = qs.filter(commune=commune)

        status_map = dict(Dossier.Status.choices)
        data = [
            {
                'status': i['status'],
                'status_display': status_map.get(i['status'], i['status']),
                'count': i['count'],
            }
            for i in qs.values('status').annotate(count=Count('id')).order_by('status')
        ]

        _cache_set(cache_key, data, CACHE_TTL_SHORT)
        return data

    @staticmethod
    def get_count_by_type(commune=None):
        """Nombre de dossiers par type avec cache."""
        cache_key = _cache_key('by_type', commune)
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        qs = Dossier.objects.all()
        if commune:
            qs = qs.filter(commune=commune)

        type_map = dict(Dossier.Type.choices)
        data = [
            {
                'type': i['type'],
                'type_display': type_map.get(i['type'], i['type']),
                'count': i['count'],
            }
            for i in qs.values('type').annotate(count=Count('id')).order_by('type')
        ]

        _cache_set(cache_key, data, CACHE_TTL_SHORT)
        return data

    @staticmethod
    def get_count_by_commune():
        """Nombre de dossiers par commune (super_admin uniquement)."""
        cache_key = _cache_key('by_commune')
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        data = list(
            Dossier.objects.values('commune__name', 'commune__region')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        _cache_set(cache_key, data, CACHE_TTL_MEDIUM)
        return data

    # ── VOLUMES & TENDANCES ──

    @staticmethod
    def get_daily_volume(commune=None, days=30):
        """Volume quotidien de dossiers avec cache."""
        cache_key = _cache_key('daily_volume', commune, days=days)
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        since = timezone.now() - timedelta(days=days)
        qs = Dossier.objects.filter(created_at__gte=since)
        if commune:
            qs = qs.filter(commune=commune)

        data = list(
            qs.annotate(date=TruncDate('created_at'))
            .values('date')
            .annotate(count=Count('id'))
            .order_by('date')
        )

        _cache_set(cache_key, data, CACHE_TTL_SHORT)
        return data

    # ── PERFORMANCE AGENTS (OPTIMISÉ — ZÉRO N+1 QUERY) ──

    @staticmethod
    def get_agent_performance(commune=None):
        """
        Performance des agents — Requête 100% agrégée côté DB.

        Avant (N+1) : 1 requête par agent = 100 agents → 300+ requêtes DB.
        Après (optimisé) : 1 seule requête avec annotate() = TOUJOURS 1 requête.
        """
        cache_key = _cache_key('agent_perf', commune)
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        agent_qs = User.objects.filter(is_active=True).exclude(role='citizen')
        if commune:
            agent_qs = agent_qs.filter(commune=commune)

        # ── UNE SEULE REQUÊTE — agrégation complète côté DB ──
        agents = agent_qs.annotate(
            total_assigned=Count(
                'assigned_dossiers',
            ),
            total_completed=Count(
                'assigned_dossiers',
                filter=Q(assigned_dossiers__status__in=[
                    Dossier.Status.COMPLETED,
                    Dossier.Status.APPROVED,
                ]),
            ),
            total_rejected=Count(
                'assigned_dossiers',
                filter=Q(assigned_dossiers__status=Dossier.Status.REJECTED),
            ),
            avg_processing_time=Avg(
                ExpressionWrapper(
                    F('assigned_dossiers__completed_at') - F('assigned_dossiers__submitted_at'),
                    output_field=DurationField(),
                ),
                filter=Q(
                    assigned_dossiers__submitted_at__isnull=False,
                    assigned_dossiers__completed_at__isnull=False,
                ),
            ),
        ).order_by('-total_completed')

        data = [
            {
                'agent_id': agent.id,
                'agent_name': agent.full_name,
                'agent_role': agent.get_role_display(),
                'total_assigned': agent.total_assigned,
                'total_completed': agent.total_completed,
                'total_rejected': agent.total_rejected,
                'avg_processing_hours': (
                    round(agent.avg_processing_time.total_seconds() / 3600, 2)
                    if agent.avg_processing_time else None
                ),
            }
            for agent in agents
        ]

        _cache_set(cache_key, data, CACHE_TTL_MEDIUM)
        return data

    # ── DÉLAIS DE TRAITEMENT ──

    @staticmethod
    def get_processing_delays(commune=None):
        """Délais de traitement par type de dossier avec cache."""
        cache_key = _cache_key('delays', commune)
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data

        qs = Dossier.objects.filter(
            submitted_at__isnull=False,
            completed_at__isnull=False,
        )
        if commune:
            qs = qs.filter(commune=commune)

        qs = qs.annotate(
            processing_time=ExpressionWrapper(
                F('completed_at') - F('submitted_at'),
                output_field=DurationField(),
            )
        )
        type_map = dict(Dossier.Type.choices)

        raw_data = qs.values('type').annotate(
            avg_time=Avg('processing_time'),
            min_time=Min('processing_time'),
            max_time=Max('processing_time'),
            total_processed=Count('id'),
        )

        data = [
            {
                'type': i['type'],
                'type_display': type_map.get(i['type'], i['type']),
                'avg_hours': round(i['avg_time'].total_seconds() / 3600, 2) if i['avg_time'] else None,
                'min_hours': round(i['min_time'].total_seconds() / 3600, 2) if i['min_time'] else None,
                'max_hours': round(i['max_time'].total_seconds() / 3600, 2) if i['max_time'] else None,
                'total_processed': i['total_processed'],
            }
            for i in raw_data
        ]

        _cache_set(cache_key, data, CACHE_TTL_MEDIUM)
        return data

    # ── DOSSIERS RÉCENTS ──

    @staticmethod
    def get_recent_dossiers(commune=None, limit=10):
        """Derniers dossiers avec select_related pour zéro requête supplémentaire."""
        qs = Dossier.objects.select_related(
            'citizen', 'commune', 'assigned_agent',
        ).order_by('-created_at')

        if commune:
            qs = qs.filter(commune=commune)

        return [
            {
                'id': d.id,
                'reference': d.reference,
                'type': d.type,
                'type_display': d.get_type_display(),
                'status': d.status,
                'status_display': d.get_status_display(),
                'citizen_name': d.citizen.full_name,
                'commune_name': d.commune.name,
                'created_at': d.created_at,
                'submitted_at': d.submitted_at,
            }
            for d in qs[:limit]
        ]

    # ── DOSSIERS EN ATTENTE (STALE) ──

    @staticmethod
    def get_stale_dossiers(commune=None, stale_hours=48):
        """Dossiers bloqués depuis plus de N heures."""
        threshold = timezone.now() - timedelta(hours=stale_hours)
        qs = Dossier.objects.filter(
            status__in=[Dossier.Status.SUBMITTED, Dossier.Status.IN_REVIEW],
            submitted_at__lte=threshold,
        ).select_related('citizen', 'commune', 'assigned_agent')

        if commune:
            qs = qs.filter(commune=commune)

        return qs
