from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.db.models import Count
from django.shortcuts import get_object_or_404
from apps.etat_civil.models_attribution import ProfilAgent, AttributionDossier, JournalAttribution
from apps.etat_civil.services.service_attribution import ServiceAttribution
from apps.etat_civil.services.moteur_scoring import MoteurScoring
from apps.dossiers.models import Dossier
from apps.users.models import User
from apps.shared.pagination import StandardPagination

from apps.shared.permissions import IsAdminStaff
from rest_framework.exceptions import PermissionDenied

class StatsAttributionView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def get(self, request):
        qs = Dossier.objects.all()
        if request.user.role in ['civil_admin', 'civil_admin_supervisor']:
            qs = qs.filter(commune=request.user.commune)
            
        total = qs.count()
        en_attente = qs.filter(status='soumis').count()
        en_traitement = qs.filter(status='in_review').count()
        termines = qs.filter(status='termine').count()
        rejetes = qs.filter(status='rejete').count()

        return Response({
            'total': total,
            'en_attente': en_attente,
            'en_traitement': en_traitement,
            'termines': termines,
            'rejetes': rejetes
        })

class AgentsChargeView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def get(self, request):
        agents_qs = ProfilAgent.objects.filter(user__is_active=True).select_related('user')
        if request.user.role in ['civil_admin', 'civil_admin_supervisor']:
            agents_qs = agents_qs.filter(user__commune=request.user.commune)
            
        agents = agents_qs
        data = []
        for agent in agents:
            en_cours = AttributionDossier.objects.filter(agent_actuel=agent.user, dossier__status='in_review').count()
            data.append({
                'id': agent.user.id,
                'email': agent.user.email,
                'nom': agent.user.full_name,
                'score_global': agent.score_global,
                'charge_maximale': agent.charge_maximale,
                'dossiers_en_cours': en_cours,
                'disponibilite': agent.disponibilite
            })
        return Response(data)

class CarteAttributionView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]
    pagination_class = StandardPagination

    def get(self, request):
        queryset = AttributionDossier.objects.filter(dossier__status='in_review').select_related('dossier', 'agent_actuel').order_by('-date_attribution')
        if request.user.role in ['civil_admin', 'civil_admin_supervisor']:
            queryset = queryset.filter(dossier__commune=request.user.commune)
        paginator = self.pagination_class()
        page = paginator.paginate_queryset(queryset, request)
        
        data = []
        for attr in page:
            data.append({
                'id': attr.id,
                'dossier_id': attr.dossier.id,
                'dossier_type': getattr(attr.dossier, 'type', 'inconnu'),
                'agent_email': attr.agent_actuel.email,
                'score': attr.score_attribution,
                'priorite': attr.niveau_priorite,
                'justification_ia': attr.justification_ia,
                'date_attribution': attr.date_attribution
            })
        return paginator.get_paginated_response(data)

class JournalAttributionView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]
    pagination_class = StandardPagination

    def get(self, request):
        queryset = JournalAttribution.objects.all().order_by('-timestamp')
        if request.user.role in ['civil_admin', 'civil_admin_supervisor']:
            dossiers_ids = list(Dossier.objects.filter(commune=request.user.commune).values_list('id', flat=True))
            dossiers_ids_str = [str(d_id) for d_id in dossiers_ids]
            queryset = queryset.filter(dossier_id__in=dossiers_ids_str)
        paginator = self.pagination_class()
        page = paginator.paginate_queryset(queryset, request)
        
        data = []
        for log in page:
            data.append({
                'id': log.id,
                'timestamp': log.timestamp,
                'action': log.libelle_action,
                'dossier_id': log.dossier_id,
                'agent_avant': log.agent_avant,
                'agent_apres': log.agent_apres,
                'score': log.score_calcule,
                'responsable': log.responsable.email if log.responsable else 'Système'
            })
        return paginator.get_paginated_response(data)

class ReattribuerDossierView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def post(self, request, dossier_id):
        if request.user.role == 'civil_admin_supervisor':
            raise PermissionDenied("Action non autorisée pour le superviseur.")
        dossier = get_object_or_404(Dossier, id=dossier_id)
        nouvel_agent_id = request.data.get('agent_id')
        raison = request.data.get('raison')

        if not nouvel_agent_id or not raison:
            return Response({"error": "agent_id et raison sont requis."}, status=status.HTTP_400_BAD_REQUEST)

        nouvel_agent = get_object_or_404(User, id=nouvel_agent_id)
        service = ServiceAttribution()
        attribution, message = service.reattribuer(
            dossier=dossier,
            nouvel_agent_user=nouvel_agent,
            source='superviseur',
            responsable=request.user,
            justification_manuelle=raison
        )

        if attribution:
            return Response({"message": message})
        return Response({"error": message}, status=status.HTTP_400_BAD_REQUEST)

class SuspendreAttributionView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def post(self, request):
        if request.user.role == 'civil_admin_supervisor':
            raise PermissionDenied("Action non autorisée pour le superviseur.")
        commune_id = request.data.get('commune_id')
        duree = int(request.data.get('duree_heures', 24))
        if not commune_id:
            return Response({"error": "commune_id requis."}, status=status.HTTP_400_BAD_REQUEST)
        
        service = ServiceAttribution()
        msg = service.suspendre_attribution_auto(commune_id, duree)
        return Response({"message": msg})

class AgentPerformanceView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def get(self, request, agent_id):
        agent = get_object_or_404(ProfilAgent, user__id=agent_id)
        return Response({
            'score_global': agent.score_global,
            'temps_moyen': agent.temps_moyen_traitement,
            'taux_reussite': agent.taux_reussite,
            'taux_respect_delais': agent.taux_respect_delais
        })

class RecommandationAgentView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def get(self, request, dossier_id):
        dossier = get_object_or_404(Dossier, id=dossier_id)
        moteur = MoteurScoring()
        agents = ProfilAgent.objects.filter(user__is_active=True, disponibilite=True)
        
        scores = []
        for agent in agents:
            res = moteur.calculer_score_agent(agent, dossier)
            scores.append({
                'agent_id': agent.user.id,
                'email': agent.user.email,
                'score': res['score_total'],
                'details': res['details'],
                'justification': moteur._generer_justification(agent, res)
            })
        
        scores.sort(key=lambda x: x['score'], reverse=True)
        return Response(scores[:3])

class DispatchingGlobalView(APIView):
    """
    Déclenche le dispatching automatique pour tous les dossiers en attente
    de la commune de l'utilisateur (ou tous pour un super_admin).
    """
    permission_classes = [permissions.IsAuthenticated, IsAdminStaff]

    def post(self, request):
        if request.user.role == 'civil_admin_supervisor':
            raise PermissionDenied("Action non autorisée pour le superviseur.")
            
        # Trouver les dossiers soumis et non assignés
        qs = Dossier.objects.filter(
            status__in=['soumis', 'submitted', Dossier.Status.SUBMITTED],
            assigned_agent__isnull=True
        )
        
        if request.user.role == 'civil_admin' and request.user.commune:
            qs = qs.filter(commune=request.user.commune)
            
        dossiers_a_traiter = list(qs)
        if not dossiers_a_traiter:
            return Response({"message": "Aucun dossier en attente de dispatching."}, status=status.HTTP_200_OK)

        service = ServiceAttribution()
        succes = 0
        erreurs = 0
        
        for dossier in dossiers_a_traiter:
            attribution, msg = service.attribuer(dossier)
            if attribution:
                succes += 1
            else:
                erreurs += 1
                
        return Response({
            "message": f"Dispatching terminé. {succes} dossiers assignés, {erreurs} échecs.",
            "succes": succes,
            "erreurs": erreurs
        })

