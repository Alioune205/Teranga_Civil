from django.contrib import admin
from unfold.admin import ModelAdmin
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier, JournalAttribution

@admin.register(ProfilAgent)
class ProfilAgentAdmin(ModelAdmin):
    list_display = ('user', 'charge_maximale', 'disponibilite', 'score_global', 'taux_reussite', 'temps_moyen_traitement')
    list_filter = ('disponibilite',)
    search_fields = ('user__email', 'user__first_name', 'user__last_name')
    readonly_fields = ('score_global', 'taux_reussite', 'taux_respect_delais')

@admin.register(AttributionDossier)
class AttributionDossierAdmin(ModelAdmin):
    list_display = ('dossier', 'agent_actuel', 'niveau_priorite', 'date_limite_traitement', 'source_attribution')
    list_filter = ('niveau_priorite', 'source_attribution', 'est_reattribution')
    search_fields = ('dossier__reference', 'agent_actuel__email')
    readonly_fields = ('score_attribution', 'date_attribution')

@admin.register(JournalAttribution)
class JournalAttributionAdmin(ModelAdmin):
    list_display = ('dossier_id', 'libelle_action', 'agent_apres', 'timestamp')
    list_filter = ('libelle_action',)
    search_fields = ('dossier_id', 'justification')
    readonly_fields = ('dossier_id', 'agent_avant', 'agent_apres', 'libelle_action', 'justification', 'timestamp')
    
    def has_add_permission(self, request):
        return False
