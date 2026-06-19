"""
URL configuration for the Dashboard app.
"""
from django.urls import path
from .views import (
    DashboardStatsView,
    GlobalStatsView,
    PerformanceStatsView,
    ActivityStatsView,
    ExportDossiersCSVView,
    WorkloadStatsView,
)
from .superadmin_views import (
    SuperAdminOverviewView,
    CommunePerformanceView,
    SuperAdminChartsView,
    SystemActivityView,
    AuditSecurityView,
    SuperAdminPassationView,
    SuperAdminAlertsView,
    SuperAdminCommuneManagerView,
    SuperAdminCommuneToggleView,
)

urlpatterns = [
    path('stats/', DashboardStatsView.as_view(), name='dashboard-stats'),
    path('global-stats/', GlobalStatsView.as_view(), name='global-stats'),
    path('performance/', PerformanceStatsView.as_view(), name='performance-stats'),
    path('activity/', ActivityStatsView.as_view(), name='activity-stats'),
    path('export/', ExportDossiersCSVView.as_view(), name='dashboard-export'),
    path('export/csv/', ExportDossiersCSVView.as_view(), name='export-csv'),
    path('workload/', WorkloadStatsView.as_view(), name='workload-stats'),
    
    # Super Admin Routes
    path('superadmin/overview/', SuperAdminOverviewView.as_view(), name='superadmin-overview'),
    # Note: Using performance route instead of /superadmin/communes/ to not shadow management endpoint
    path('superadmin/communes/performance/', CommunePerformanceView.as_view(), name='superadmin-communes-performance'),
    path('superadmin/charts/', SuperAdminChartsView.as_view(), name='superadmin-charts'),
    path('superadmin/activity/', SystemActivityView.as_view(), name='superadmin-activity'),
    path('superadmin/audit/', AuditSecurityView.as_view(), name='superadmin-audit'),
    path('superadmin/passation/', SuperAdminPassationView.as_view(), name='superadmin-passation'),
    path('superadmin/alerts/', SuperAdminAlertsView.as_view(), name='superadmin-alerts'),
    
    # New Mairie Management routes
    path('superadmin/communes/manage/', SuperAdminCommuneManagerView.as_view(), name='superadmin-communes-manage'),
    path('superadmin/communes/<uuid:pk>/toggle-status/', SuperAdminCommuneToggleView.as_view(), name='superadmin-communes-toggle'),
]
