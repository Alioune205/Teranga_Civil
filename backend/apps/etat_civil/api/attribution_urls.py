from django.urls import path
from apps.etat_civil.api import attribution_views

urlpatterns = [
    path('stats/', attribution_views.StatsAttributionView.as_view(), name='attribution-stats'),
    path('agents/charge/', attribution_views.AgentsChargeView.as_view(), name='agents-charge'),
    path('dossiers/carte/', attribution_views.CarteAttributionView.as_view(), name='dossiers-carte'),
    path('journal/', attribution_views.JournalAttributionView.as_view(), name='journal-attribution'),
    path('dossier/<str:dossier_id>/reattribuer/', attribution_views.ReattribuerDossierView.as_view(), name='reattribuer-dossier'),
    path('attribution/suspendre/', attribution_views.SuspendreAttributionView.as_view(), name='suspendre-attribution'),
    path('agents/<int:agent_id>/performance/', attribution_views.AgentPerformanceView.as_view(), name='agent-performance'),
    path('recommandation/<str:dossier_id>/', attribution_views.RecommandationAgentView.as_view(), name='recommandation-agent'),
    path('dispatching/global/', attribution_views.DispatchingGlobalView.as_view(), name='dispatching-global'),
]
