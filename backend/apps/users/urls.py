"""
URL configuration for the Users app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import UserViewSet, CitizenProfileViewSet

router = DefaultRouter()
router.register(r'', UserViewSet, basename='user')

# Profiles are mounted at /api/profiles/ from config/urls.py level
# but we register them here for organizational clarity.
profiles_router = DefaultRouter()
profiles_router.register(r'', CitizenProfileViewSet, basename='profile')

urlpatterns = [
    path('', include(router.urls)),
]

# These will be included separately in config/urls.py
profiles_urlpatterns = [
    path('', include(profiles_router.urls)),
]
