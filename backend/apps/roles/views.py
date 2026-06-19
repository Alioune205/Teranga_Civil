"""
Views for role management.
"""
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from drf_spectacular.utils import extend_schema

from django.contrib.auth import get_user_model

from apps.shared.permissions import IsAdminStaff, IsSuperAdmin
from apps.shared.responses import success_response

from .serializers import RoleSerializer, RoleAssignSerializer

User = get_user_model()


class RoleListView(APIView):
    """
    GET /api/roles/

    List all available roles.
    """
    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(
        tags=['Roles'],
        summary='Lister les rôles',
        description='Retourne la liste de tous les rôles disponibles.',
        responses={200: RoleSerializer(many=True)},
    )
    def get(self, request):
        roles = [
            {'value': choice[0], 'label': choice[1]}
            for choice in User.Role.choices
        ]
        serializer = RoleSerializer(roles, many=True)
        return success_response(data=serializer.data)


class RoleAssignView(APIView):
    """
    POST /api/roles/assign/

    Assign a role to a user. Super admin only.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    @extend_schema(
        tags=['Roles'],
        summary='Assigner un rôle',
        description='Assigne un rôle à un utilisateur. Réservé au super administrateur.',
        request=RoleAssignSerializer,
    )
    def post(self, request):
        serializer = RoleAssignSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = User.objects.get(id=serializer.validated_data['user_id'])
        new_role = serializer.validated_data['role']
        old_role = user.role

        user.role = new_role

        # Set is_staff for admin roles
        user.is_staff = new_role in [
            User.Role.CIVIL_ADMIN,
            User.Role.SUPER_ADMIN,
        ]

        user.save(update_fields=['role', 'is_staff', 'updated_at'])

        return success_response(
            data={
                'user_id': str(user.id),
                'email': user.email,
                'old_role': old_role,
                'new_role': new_role,
            },
            message=f'Rôle de {user.full_name} mis à jour : {old_role} → {new_role}.',
        )
