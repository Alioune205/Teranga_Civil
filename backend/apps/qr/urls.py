"""
URL configuration for QR.
# TODO: DEV 2 — Implement URLs here
"""
from django.urls import path
from .views import verify_document

urlpatterns = [
    path(
        'verify/<str:reference>/',
        verify_document,
        name='qr_verify_document'
    ),
]
