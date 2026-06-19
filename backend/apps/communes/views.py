"""
Views for Commune management.
"""
from rest_framework import viewsets, status, generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from django.conf import settings

from drf_spectacular.utils import extend_schema_view, extend_schema, OpenApiParameter, OpenApiTypes

from apps.shared.permissions import IsSuperAdmin
from apps.shared.responses import success_response, error_response, not_found_response

from .models import Commune, Mairie
from .serializers import CommuneSerializer, CommuneListSerializer, MairieSerializer, MairieAvecDistanceSerializer
from .services import haversine_distance, valider_coordonnees, get_itineraire_google


@extend_schema_view(
    list=extend_schema(tags=['Communes'], summary='Lister les communes'),
    retrieve=extend_schema(tags=['Communes'], summary='Détail d\'une commune'),
    create=extend_schema(tags=['Communes'], summary='Créer une commune'),
    update=extend_schema(tags=['Communes'], summary='Modifier une commune'),
    partial_update=extend_schema(tags=['Communes'], summary='Modifier partiellement une commune'),
    destroy=extend_schema(tags=['Communes'], summary='Supprimer une commune'),
)
class CommuneViewSet(viewsets.ModelViewSet):
    """
    CRUD ViewSet for Communes.
    - List/Retrieve: Public access (AllowAny)
    - Create/Update/Delete: Super admin only
    """
    queryset = Commune.objects.all()
    filterset_fields = ['region', 'department', 'is_active']
    search_fields = ['name', 'region', 'department', 'code']
    ordering_fields = ['name', 'region', 'created_at']
    ordering = ['name']

    def get_serializer_class(self):
        if self.action == 'list':
            return CommuneListSerializer
        return CommuneSerializer

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [AllowAny()]
        return [IsAuthenticated(), IsSuperAdmin()]

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return success_response(data=serializer.data)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)


class MairiesProchesView(APIView):
    """
    GET /api/mairies/proches/?lat=14.693&lng=-17.447
    Retourne les mairies de la commune du citoyen connecté, triées par distance.
    """
    permission_classes = [IsAuthenticated]

    @extend_schema(
        tags=['Mairies'],
        summary='Lister les mairies proches',
        parameters=[
            OpenApiParameter(name='lat', type=OpenApiTypes.NUMBER, location=OpenApiParameter.QUERY, description='Latitude'),
            OpenApiParameter(name='lng', type=OpenApiTypes.NUMBER, location=OpenApiParameter.QUERY, description='Longitude'),
        ]
    )
    def get(self, request):
        try:
            commune = request.user.commune
        except AttributeError:
            return not_found_response(message="Profil utilisateur invalide.")

        if not commune:
            return error_response(message="Commune non renseignée dans votre profil.")

        lat_str = request.query_params.get('lat')
        lng_str = request.query_params.get('lng')

        if not lat_str or not lng_str:
            return error_response(message="Paramètres lat et lng requis. Ex: ?lat=14.693&lng=-17.447")

        try:
            lat = float(lat_str)
            lng = float(lng_str)
            valider_coordonnees(lat, lng)
        except ValueError as e:
            return error_response(message=str(e))

        mairies = Mairie.objects.filter(
            commune=commune, est_active=True
        ).select_related('commune')

        fallback = False
        if not mairies.exists():
            mairies = Mairie.objects.filter(
                commune__region=commune.region, est_active=True
            ).select_related('commune')
            fallback = True

        mairies_list = list(mairies)
        for mairie in mairies_list:
            mairie.distance_km = haversine_distance(
                lat, lng, float(mairie.latitude), float(mairie.longitude)
            )
        mairies_list.sort(key=lambda m: m.distance_km)

        serializer = MairieAvecDistanceSerializer(mairies_list, many=True)
        return success_response(
            data={
                "commune": commune.name,
                "fallback_region": fallback,
                "count": len(mairies_list),
                "mairies": serializer.data,
            },
            message=(
                "Aucune mairie dans votre commune. Mairies de la région affichées."
                if fallback else "Mairies récupérées avec succès."
            )
        )


class ItineraireVersMairieView(APIView):
    """
    GET /api/mairies/<id>/itineraire/?lat=14.693&lng=-17.447&mode=driving
    Proxy sécurisé : appelle Google Maps côté serveur et retourne l'itinéraire.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'google_maps_api'

    @extend_schema(
        tags=['Mairies'],
        summary='Obtenir l\'itinéraire vers une mairie',
        parameters=[
            OpenApiParameter(name='lat', type=OpenApiTypes.NUMBER, location=OpenApiParameter.QUERY, description='Latitude de départ'),
            OpenApiParameter(name='lng', type=OpenApiTypes.NUMBER, location=OpenApiParameter.QUERY, description='Longitude de départ'),
            OpenApiParameter(name='mode', type=OpenApiTypes.STR, location=OpenApiParameter.QUERY, description='Mode (driving, walking...)', default='driving'),
        ]
    )
    def get(self, request, pk):
        try:
            mairie = Mairie.objects.select_related('commune').get(pk=pk, est_active=True)
        except Mairie.DoesNotExist:
            return not_found_response(message="Mairie introuvable.")

        lat_str = request.query_params.get('lat')
        lng_str = request.query_params.get('lng')
        mode = request.query_params.get('mode', 'driving')

        if mode not in ['driving', 'walking', 'bicycling', 'transit']:
            return error_response(message="Mode invalide. Valeurs acceptées : driving, walking, bicycling, transit")

        if not lat_str or not lng_str:
            return error_response(message="Paramètres lat et lng requis.")

        try:
            lat = float(lat_str)
            lng = float(lng_str)
            valider_coordonnees(lat, lng)
        except ValueError as e:
            return error_response(message=str(e))

        try:
            itineraire = get_itineraire_google(
                lat_depart=lat,
                lng_depart=lng,
                lat_arrivee=float(mairie.latitude),
                lng_arrivee=float(mairie.longitude),
                mode=mode,
            )
        except Exception as e:
            return error_response(message=str(e), status_code=status.HTTP_502_BAD_GATEWAY)

        return success_response(
            data={
                "mairie": {
                    "id": mairie.id,
                    "nom": mairie.nom,
                    "adresse": mairie.adresse,
                    "latitude": str(mairie.latitude),
                    "longitude": str(mairie.longitude),
                    "commune": mairie.commune.name,
                },
                "depart": {"latitude": lat, "longitude": lng},
                "mode": mode,
                "itineraire": itineraire,
            },
            message="Itinéraire généré avec succès."
        )


class MairieDetailView(generics.RetrieveAPIView):
    """GET /api/mairies/<id>/"""
    queryset = Mairie.objects.filter(est_active=True).select_related('commune')
    serializer_class = MairieSerializer
    permission_classes = [IsAuthenticated]
