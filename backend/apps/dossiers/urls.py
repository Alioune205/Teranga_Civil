"""
URL configuration for the Dossiers app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DossierViewSet, agent_soumettre_au_maire, maire_approuver, maire_rejeter

router = DefaultRouter()
router.register(r'', DossierViewSet, basename='dossier')

urlpatterns = [
    path('', include(router.urls)),
    path('<uuid:dossier_id>/soumettre-maire/', agent_soumettre_au_maire),
    path('<uuid:dossier_id>/approuver/',       maire_approuver),
    path('<uuid:dossier_id>/rejeter/',         maire_rejeter),
]
