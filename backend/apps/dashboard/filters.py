"""
Dashboard filters — Filtres pour les endpoints de statistiques.
"""
from django.utils import timezone
from datetime import timedelta


class DashboardFilterMixin:
    """
    Mixin pour extraire les paramètres de filtrage communs
    des query params des vues dashboard.
    """

    def get_commune_filter(self):
        """
        Retourne la commune à filtrer :
        - Agents normaux : leur propre commune (forcé)
        - Super admin : commune passée en query param ou None (= toutes)
        """
        user = self.request.user
        if user.role == 'super_admin':
            commune_id = self.request.query_params.get('commune', None)
            if commune_id:
                from apps.communes.models import Commune
                try:
                    return Commune.objects.get(id=commune_id)
                except Commune.DoesNotExist:
                    return None
            return None  # Super admin voit tout
        return user.commune  # Agents voient leur commune

    def get_days_filter(self):
        """Nombre de jours pour les filtres temporels (défaut: 30)."""
        try:
            days = int(self.request.query_params.get('days', 30))
            return min(max(days, 1), 365)  # Entre 1 et 365 jours
        except (ValueError, TypeError):
            return 30

    def get_limit_filter(self):
        """Nombre max de résultats (défaut: 10)."""
        try:
            limit = int(self.request.query_params.get('limit', 10))
            return min(max(limit, 1), 100)
        except (ValueError, TypeError):
            return 10
