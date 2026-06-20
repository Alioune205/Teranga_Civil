"""
URL configuration for the Dossiers app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DossierViewSet, agent_soumettre_au_superviseur, superviseur_approuver, superviseur_rejeter

router = DefaultRouter()
router.register(r'', DossierViewSet, basename='dossier')

urlpatterns = [
    path('', include(router.urls)),
    path('<uuid:dossier_id>/soumettre-superviseur/', agent_soumettre_au_superviseur),
    path('<uuid:dossier_id>/approuver/',             superviseur_approuver),
    path('<uuid:dossier_id>/rejeter/',               superviseur_rejeter),
]
