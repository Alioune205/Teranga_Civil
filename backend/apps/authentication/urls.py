"""
URL configuration for the Authentication app.
"""
from django.urls import path

from .views import LoginView, RegisterView, CustomTokenRefreshView, LogoutView, SendOTPView, VerifyOTPView, LoginHistoryView, ChangePasswordView

urlpatterns = [
    path('login/', LoginView.as_view(), name='auth-login'),
    path('register/', RegisterView.as_view(), name='auth-register'),
    path('refresh/', CustomTokenRefreshView.as_view(), name='auth-refresh'),
    path('logout/', LogoutView.as_view(), name='auth-logout'),
    path('otp/send/', SendOTPView.as_view(), name='auth-otp-send'),
    path('otp/verify/', VerifyOTPView.as_view(), name='auth-otp-verify'),
    path('login-history/', LoginHistoryView.as_view(), name='auth-login-history'),
    path('change-password/', ChangePasswordView.as_view(), name='auth-change-password'),
]

