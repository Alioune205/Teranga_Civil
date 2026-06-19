import uuid
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.filters import SearchFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction

from ..models_citoyen import Citoyen
from apps.dossiers.models import Dossier
from apps.payments.models import PaymentTransaction, PaymentType, PaymentStatus
from apps.etat_civil.models_attribution import AttributionDossier
from .citoyen_serializers import (
    CitoyenListSerializer, CitoyenDetailSerializer,
    CitoyenCreateSerializer, GuichetRapideSerializer
)
from apps.shared.utils import generate_reference

class CitoyenViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend, SearchFilter]
    filterset_fields = ['commune_id', 'quartier']
    search_fields = ['nom', 'prenom', 'telephone', 'numero_cni']

    def get_queryset(self):
        user = self.request.user
        qs = Citoyen.objects.all()
        if not user.is_authenticated:
            return qs.none()
        if getattr(user, 'role', None) == 'super_admin':
            return qs
        if hasattr(user, 'commune') and user.commune:
            return qs.filter(commune=user.commune)
        return qs.none()

    def get_serializer_class(self):
        if self.action == 'list':
            return CitoyenListSerializer
        elif self.action == 'create' or self.action == 'update' or self.action == 'partial_update':
            return CitoyenCreateSerializer
        return CitoyenDetailSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def guichet(self, request, pk=None):
        citoyen = self.get_object()
        # Support both JSON and multipart/form-data
        input_data = request.data
        if hasattr(request.data, 'dict'):
            input_data = request.data.dict()
            
        # Parse data with serializer
        serializer = GuichetRapideSerializer(data=input_data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        
        import random
        prenoms_garcons = ["Amadou", "Mamadou", "Ousmane", "Ibrahima", "Abdoulaye", "Cheikh", "Moussa", "Alioune", "Saliou"]
        prenoms_filles = ["Fatou", "Awa", "Aminata", "Ndeye", "Khady", "Mariama", "Aissatou", "Oumou", "Seynabou"]
        noms_famille = ["Ndiaye", "Diop", "Fall", "Sarr", "Gueye", "Seck", "Faye", "Sy", "Sow", "Ba", "Thiam", "Toure"]

        # Construire les metadonnées pour que le PDF ne soit pas vide
        metadata = {
            'prenoms_enfant': citoyen.prenom,
            'nom_enfant': citoyen.nom,
            'date_naissance_personne': str(citoyen.date_naissance),
            'lieu_naissance': citoyen.lieu_naissance or 'N/A',
            'sexe': citoyen.get_sexe_display(),
            # Informations générées aléatoirement pour la démo
            'prenom_pere': random.choice(prenoms_garcons),
            'prenom_mere': random.choice(prenoms_filles),
            'nom_mere': random.choice(noms_famille),
            'annee_registre': str(timezone.now().year),
            'numero_registre': str(random.randint(1, 99999))
        }
        
        # Override metadata for residence certificate if provided in form data
        if input_data.get('type_document') == 'residence_certificate' or input_data.get('type_acte') == 'residence':
            if 'adresse_residence' in input_data:
                metadata['adresse'] = input_data['adresse_residence']
            if 'duree_residence' in input_data:
                # La valeur contient déjà l'unité (ex: "1 an", "2 ans", "6 mois")
                # → ne pas ajouter "ans" pour éviter le doublon "1 an ans"
                metadata['date_installation'] = f"il y a {input_data['duree_residence']}"
            if 'nom_complet' in input_data:
                parts = input_data['nom_complet'].split(' ', 1)
                if len(parts) > 1:
                    metadata['prenoms_requerant'] = parts[0]
                    metadata['nom_requerant'] = parts[1]
                else:
                    metadata['prenoms_requerant'] = parts[0]
                    metadata['nom_requerant'] = ''
            if 'date_naissance' in input_data:
                metadata['date_naissance'] = input_data['date_naissance']
            # Récupérer le quartier depuis le profil citoyen si non déjà défini
            if not metadata.get('quartier') and citoyen.quartier:
                metadata['quartier'] = citoyen.quartier
                
        # Override metadata for regularisation, autorisation de construire, mutation_parcelle
        if input_data.get('type_document') in ['regularisation', 'autorisation_construire', 'mutation_parcelle']:
            fields = [
                'nom_complet_requerant', 'numero_cni', 'telephone', 'adresse', 
                'localisation_terrain', 'quartier_village', 'superficie', 'reference_cadastrale'
            ]
            for f in fields:
                if f in input_data:
                    metadata[f] = input_data[f]
        
        
        # 1. Créer une Demande avec statut COMPLETED
        dossier = Dossier.objects.create(
            type=data['type_document'],
            status=Dossier.Status.COMPLETED,
            citoyen_guichet=citoyen,
            commune=citoyen.commune,
            notes=data.get('motif', ''),
            submitted_at=timezone.now(),
            reviewed_at=timezone.now(),
            completed_at=timezone.now(),
            assigned_agent=request.user,
            metadata=metadata
        )
        
        # Save uploaded files if any
        if request.FILES:
            from apps.documents.models import Document
            for f in request.FILES.getlist('pieces_jointes'):
                Document.objects.create(
                    dossier=dossier,
                    file=f,
                    file_type='image',
                    uploaded_by=request.user
                )
        
        # 2. Créer un enregistrement Paiement
        # Map paiement_mode to PaymentType
        payment_mapping = {
            'espèces': PaymentType.CASH,
            'wave': PaymentType.WAVE,
            'orange money': PaymentType.ORANGE_MONEY,
            'free money': PaymentType.FREE_MONEY,
            'exonéré': PaymentType.CASH # Par défaut on traite comme cash à 0 si exonéré
        }
        pm = data['paiement_mode'].lower()
        ptype = payment_mapping.get(pm, PaymentType.CASH)
        
        PaymentTransaction.objects.create(
            reference=f"PAY-{uuid.uuid4().hex[:8].upper()}",
            amount=data['montant'],
            payment_type=ptype,
            status=PaymentStatus.SUCCESS,
            payer_name=citoyen.nom_complet,
            payer_id=citoyen.telephone,
            service_label=f"Guichet Rapide: {dossier.get_type_display()}"
        )
        
        # 3. Générer le PDF du document demandé (simulé via une route ou URL existante)
        pdf_url = f"/api/dossiers/{dossier.id}/download-pdf/"
        
        # 4. Créer une AttributionDossier avec source="manuel"
        AttributionDossier.objects.create(
            dossier=dossier,
            agent_actuel=request.user,
            source_attribution='manuel',
            date_limite_traitement=timezone.now() + timezone.timedelta(days=1)
        )
        
        return Response({
            'demande_id': dossier.id,
            'pdf_url': pdf_url,
            'reference': dossier.reference
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'])
    def documents(self, request, pk=None):
        citoyen = self.get_object()
        dossiers = citoyen.dossiers.filter(status=Dossier.Status.COMPLETED).order_by('-completed_at')
        
        docs = []
        for d in dossiers:
            docs.append({
                'id': d.id,
                'reference': d.reference,
                'type': d.get_type_display(),
                'date': d.completed_at,
                'url': f"/api/dossiers/{d.id}/download-pdf/"
            })
            
        return Response(docs)
