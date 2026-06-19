from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .citoyen_views import CitoyenViewSet

router = DefaultRouter()
router.register(r'citoyens', CitoyenViewSet, basename='citoyen')

urlpatterns = [
    path('', include(router.urls)),
]
