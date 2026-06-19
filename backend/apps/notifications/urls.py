"""
URL configuration for Notifications.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import NotificationViewSet, RegisterDeviceView

router = DefaultRouter()
router.register(r'', NotificationViewSet, basename='notification')

urlpatterns = [
    path('register-device/', RegisterDeviceView.as_view(), name='register_device'),
    path('', include(router.urls)),
]
