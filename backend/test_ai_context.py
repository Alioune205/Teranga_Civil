import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

import json
from apps.users.models import User
from apps.dashboard.views import get_base_queryset
from django.db.models import Count

try:
    user = User.objects.filter(role='super_admin').first()
    qs = get_base_queryset(user)
    
    commune_name = 'Toutes les communes (Global)' if user.role == 'super_admin' else (user.commune.name if getattr(user, 'commune', None) else 'Inconnue')
    total_dossiers = qs.count()
    types = list(qs.values('type').annotate(count=Count('id')))
    statuts = list(qs.values('status').annotate(count=Count('id')))
    
    agents = list(qs.filter(assigned_agent__isnull=False).values(
        'assigned_agent__first_name', 'assigned_agent__last_name'
    ).annotate(count=Count('id')).order_by('-count'))
    
    context_data = {
        'commune': commune_name,
        'periode': 'Globale',
        'total_dossiers': total_dossiers,
        'par_type': {item['type']: item['count'] for item in types},
        'par_statut': {item['status']: item['count'] for item in statuts},
        'charge_par_agent': {
            f"{item['assigned_agent__first_name']} {item['assigned_agent__last_name']}".strip(): item['count']
            for item in agents
        }
    }
    
    print("SUCCESS")
    print(json.dumps(context_data, indent=2))
except Exception as e:
    import traceback
    traceback.print_exc()
