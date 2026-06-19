"""
URL configuration for Services.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TransactionViewSet, ReportViewSet, SurveyViewSet

app_name = 'services'

router = DefaultRouter()
router.register(r'transactions', TransactionViewSet, basename='transaction')
router.register(r'reports', ReportViewSet, basename='report')
router.register(r'surveys', SurveyViewSet, basename='survey')

urlpatterns = [
    path('', include(router.urls)),
]
