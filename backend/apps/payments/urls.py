from django.urls import path
from .views import (
    AdminTransactionListView, 
    AdminTransactionStatsView, 
    InitiatePaymentView,
    RegisterGuichetPaymentView,
    DownloadReceiptPDFView
)

urlpatterns = [
    path('v1/admin/transactions/stats', AdminTransactionStatsView.as_view(), name='admin-transactions-stats'),
    path('v1/admin/transactions', AdminTransactionListView.as_view(), name='admin-transactions'),
    path('initiate/', InitiatePaymentView.as_view(), name='payment-initiate'),
    path('guichet/register/', RegisterGuichetPaymentView.as_view(), name='payment-guichet-register'),
    path('transactions/<uuid:pk>/receipt/', DownloadReceiptPDFView.as_view(), name='payment-receipt-download'),
]
