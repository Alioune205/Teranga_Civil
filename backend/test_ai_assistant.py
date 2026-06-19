import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta
from apps.dossiers.models import Dossier
from apps.users.models import User
from groq import Groq
from django.conf import settings

def parse_period_from_question(question):
    q = question.lower()
    now = timezone.now()
    if "hier" in q:
        return now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=1), now.replace(hour=23, minute=59, second=59, microsecond=999999) - timedelta(days=1), "Hier"
    elif "aujourd'hui" in q or "ce jour" in q:
        return now.replace(hour=0, minute=0, second=0, microsecond=0), now, "Aujourd'hui"
    elif "semaine" in q:
        return now - timedelta(days=now.weekday()), now, "Cette semaine"
    elif "mois" in q:
        return now.replace(day=1, hour=0, minute=0, second=0, microsecond=0), now, "Ce mois-ci"
    return None, None, "Global"

def generate_context(user, question):
    start_date, end_date, period_label = parse_period_from_question(question)
    
    qs = Dossier.objects.all()
    if user.role == 'super_admin':
        qs = qs
        commune_name = "Toutes les communes (Global)"
    elif user.role in ['civil_admin', 'civil_admin_supervisor']:
        qs = qs.filter(commune=user.commune) if user.commune else qs.none()
        commune_name = user.commune.name if user.commune else "Inconnue"
    else:
        qs = qs.none()
        commune_name = "Inconnue"

    if start_date and end_date:
        qs = qs.filter(created_at__range=(start_date, end_date))

    # Stats: Total, par type, par statut
    total = qs.count()
    types = list(qs.values('type').annotate(count=Count('id')))
    statuts = list(qs.values('status').annotate(count=Count('id')))
    
    # Workload par agent
    agents = list(qs.filter(assigned_agent__isnull=False).values(
        'assigned_agent__first_name', 'assigned_agent__last_name'
    ).annotate(count=Count('id')).order_by('-count'))
    
    context = {
        "commune": commune_name,
        "periode": period_label,
        "total_dossiers": total,
        "par_type": {item['type']: item['count'] for item in types},
        "par_statut": {item['status']: item['count'] for item in statuts},
        "charge_par_agent": {
            f"{item['assigned_agent__first_name']} {item['assigned_agent__last_name']}": item['count']
            for item in agents
        }
    }
    return context

def query_assistant(user, question, chat_history=[]):
    context = generate_context(user, question)
    
    system_prompt = f"""Tu es un assistant analytique pour les administrateurs de mairie de Teranga Civil.
Tu dois répondre à la question de l'administrateur de manière concise, factuelle, et en français.
BASE-TOI UNIQUEMENT sur les données JSON suivantes pour formuler ta réponse :

{json.dumps(context, ensure_ascii=False, indent=2)}

RÈGLES STRICTES :
1. Ne mentionne pas que tu lis un JSON. Réponds naturellement.
2. Si la question porte sur une donnée qui n'est pas dans le JSON (ex: la météo, le nom du maire, ou des données financières si elles n'y sont pas), réponds que tu ne disposes pas de cette information pour cette période.
3. Le scope actuel est la commune : {context['commune']} sur la période : {context['periode']}. Ne donne pas de chiffres pour d'autres communes.
"""
    print("--- SYSTEM PROMPT ---")
    print(system_prompt)
    
    api_key = getattr(settings, 'GROQ_API_KEY', os.environ.get('GROQ_API_KEY'))
    client = Groq(api_key=api_key)
    
    messages = [{"role": "system", "content": system_prompt}] + chat_history
    messages.append({"role": "user", "content": question})
    
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"Erreur : {str(e)}"

if __name__ == '__main__':
    admin = User.objects.filter(role='civil_admin_supervisor').first()
    q = "Combien d'extraits de naissance avons-nous réalisés cette semaine ?"
    res = query_assistant(admin, q)
    print("\n--- RESPONSE ---")
    print(res)
