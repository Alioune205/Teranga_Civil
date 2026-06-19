"""
URL configuration for the Roles app.
"""
from django.urls import path
from .views import RoleListView, RoleAssignView

urlpatterns = [
    path('', RoleListView.as_view(), name='role-list'),
    path('assign/', RoleAssignView.as_view(), name='role-assign'),
]
