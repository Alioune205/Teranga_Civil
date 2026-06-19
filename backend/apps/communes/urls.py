"""
URL configuration for the Communes app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CommuneViewSet, MairiesProchesView, ItineraireVersMairieView, MairieDetailView

router = DefaultRouter()
router.register(r'', CommuneViewSet, basename='commune')

urlpatterns = [
    path('mairies/proches/', MairiesProchesView.as_view(), name='mairies-proches'),
    path('mairies/<int:pk>/', MairieDetailView.as_view(), name='mairie-detail'),
    path('mairies/<int:pk>/itineraire/', ItineraireVersMairieView.as_view(), name='mairie-itineraire'),
    path('', include(router.urls)),
]
