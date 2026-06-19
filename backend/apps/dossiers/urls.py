"""
URL configuration for the Dossiers app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DossierViewSet

router = DefaultRouter()
router.register(r'', DossierViewSet, basename='dossier')

urlpatterns = [
    path('', include(router.urls)),
]
