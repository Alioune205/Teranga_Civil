from rest_framework import serializers
from ..models_citoyen import Citoyen
from apps.dossiers.models import Dossier
from apps.communes.serializers import CommuneSerializer
from apps.dossiers.serializers import DossierListSerializer
from apps.users.serializers import UserListSerializer

class CitoyenListSerializer(serializers.ModelSerializer):
    commune = CommuneSerializer(read_only=True)
    nombre_demandes_total = serializers.SerializerMethodField()
    derniere_demande_date = serializers.SerializerMethodField()

    class Meta:
        model = Citoyen
        fields = [
            'id', 'prenom', 'nom', 'nom_complet', 'date_naissance', 'age', 'telephone',
            'commune', 'numero_cni', 'nombre_demandes_total',
            'derniere_demande_date', 'est_actif', 'created_at'
        ]

    def get_nombre_demandes_total(self, obj):
        return obj.dossiers.count()

    def get_derniere_demande_date(self, obj):
        last_dossier = obj.dossiers.order_by('-created_at').first()
        if last_dossier:
            return last_dossier.created_at
        return None

class CitoyenDetailSerializer(CitoyenListSerializer):
    created_by = UserListSerializer(read_only=True)
    dossiers_history = serializers.SerializerMethodField()
    
    class Meta(CitoyenListSerializer.Meta):
        fields = CitoyenListSerializer.Meta.fields + [
            'lieu_naissance', 'sexe', 'nationalite', 'nom_pere', 'nom_mere',
            'email', 'adresse', 'quartier', 'numero_passeport',
            'date_expiration_cni', 'created_by', 'dossiers_history'
        ]

    def get_dossiers_history(self, obj):
        return DossierListSerializer(obj.dossiers.all().order_by('-created_at'), many=True).data

class CitoyenCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Citoyen
        fields = [
            'prenom', 'nom', 'date_naissance', 'lieu_naissance', 'sexe',
            'nationalite', 'nom_pere', 'nom_mere', 'telephone', 'email', 'adresse', 'quartier',
            'commune', 'numero_cni', 'numero_passeport', 'date_expiration_cni'
        ]

    def validate_telephone(self, value):
        if Citoyen.objects.filter(telephone=value).exists():
            raise serializers.ValidationError("Un citoyen avec ce numéro de téléphone existe déjà.")
        return value

class GuichetRapideSerializer(serializers.Serializer):
    type_document = serializers.ChoiceField(choices=Dossier.Type.choices)
    motif = serializers.CharField(required=False, allow_blank=True)
    paiement_mode = serializers.CharField(max_length=50)
    montant = serializers.DecimalField(max_digits=10, decimal_places=2)
