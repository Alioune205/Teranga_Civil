"""
URL configuration for System — Health check, métriques, logs, info plateforme.
"""
from django.urls import path
from .views import HealthCheckView, SystemMetricsView, SystemLogsView, SystemInfoView

app_name = 'system'

urlpatterns = [
    path('health/', HealthCheckView.as_view(), name='health_check'),
    path('metrics/', SystemMetricsView.as_view(), name='metrics'),
    path('logs/', SystemLogsView.as_view(), name='logs'),
    path('info/', SystemInfoView.as_view(), name='system_info'),
]
