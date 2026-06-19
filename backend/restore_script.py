import sys
path = 'apps/ai/views.py'

content_to_append = '''

class AdminAssistantQueryView(APIView):
    """
    Assistant IA contextuel pour les administrateurs de mairie.
    Prend une question en langage naturel et répond en se basant UNIQUEMENT 
    sur les statistiques (JSON) générées en backend.
    """
    permission_classes = [IsAuthenticated, IsAdminStaff]

    @extend_schema(tags=['AI & Assistant'], summary="Poser une question à l'assistant IA (Administrateur)")
    def post(self, request, *args, **kwargs):
        try:
            # 1. Vérification stricte des rôles
            if request.user.role not in ['super_admin', 'civil_admin', 'civil_admin_supervisor']:
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Accès réservé aux administrateurs.")

            question = request.data.get('question', '').strip()
            chat_history = request.data.get('chat_history', [])

            if not question:
                return Response({'error': 'Veuillez poser une question.'}, status=400)

            # 2. Parsing de la période basique
            q_lower = question.lower()
            from django.utils import timezone
            from datetime import timedelta
            now = timezone.now()
            
            start_date = None
            end_date = None
            period_label = "Globale"

            if "hier" in q_lower:
                start_date = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=1)
                end_date = now.replace(hour=23, minute=59, second=59, microsecond=999999) - timedelta(days=1)
                period_label = "Hier"
            elif "aujourd'hui" in q_lower or "ce jour" in q_lower:
                start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
                end_date = now
                period_label = "Aujourd'hui"
            elif "semaine" in q_lower:
                start_date = now - timedelta(days=now.weekday())
                end_date = now
                period_label = "Cette semaine"
            elif "mois" in q_lower:
                start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
                end_date = now
                period_label = "Ce mois-ci"

            # 3. Récupération du contexte via ORM (Scoped)
            from apps.dashboard.views import get_base_queryset
            from django.db.models import Count
            import json
            
            qs = get_base_queryset(request.user)
            commune_name = "Toutes les communes (Global)" if request.user.role == 'super_admin' else (request.user.commune.name if getattr(request.user, 'commune', None) else "Inconnue")

            if start_date and end_date:
                qs = qs.filter(created_at__range=(start_date, end_date))

            total_dossiers = qs.count()
            types = list(qs.values('type').annotate(count=Count('id')))
            statuts = list(qs.values('status').annotate(count=Count('id')))
            
            agents = list(qs.filter(assigned_agent__isnull=False).values(
                'assigned_agent__first_name', 'assigned_agent__last_name'
            ).annotate(count=Count('id')).order_by('-count'))
            
            context_data = {
                "commune": commune_name,
                "periode": period_label,
                "total_dossiers": total_dossiers,
                "par_type": {item['type']: item['count'] for item in types},
                "par_statut": {item['status']: item['count'] for item in statuts},
                "charge_par_agent": {
                    f"{item['assigned_agent__first_name']} {item['assigned_agent__last_name']}".strip(): item['count']
                    for item in agents
                }
            }

            # 4. Construction du Prompt Système
            system_prompt = f"""Tu es l'Assistant IA analytique officiel pour les administrateurs de la mairie (Teranga Civil).
Tu dois répondre à la question de l'administrateur de manière concise, factuelle, et en français.
BASE-TOI UNIQUEMENT sur les données JSON suivantes pour formuler ta réponse :

{json.dumps(context_data, ensure_ascii=False, indent=2)}

RÈGLES STRICTES :
1. Ne mentionne jamais que tu lis un objet JSON. Parle naturellement à l'administrateur.
2. Si la question porte sur une donnée absente du contexte fourni (ex: météo, nom du maire, finances), réponds précisément que tu ne disposes pas de ces données pour l'instant.
3. Le périmètre actuel est : Commune = {context_data['commune']}, Période = {context_data['periode']}. Ne donne aucune statistique pour d'autres communes.
"""

            # 5. Appel de l'API Groq
            from groq import Groq
            from django.conf import settings
            import os

            api_key = getattr(settings, 'GROQ_API_KEY', os.environ.get('GROQ_API_KEY'))
            if not api_key:
                return Response({'error': "La clé GROQ_API_KEY n'est pas configurée sur le serveur."}, status=500)

            client = Groq(api_key=api_key)
            messages = [{"role": "system", "content": system_prompt}] + chat_history
            messages.append({"role": "user", "content": question})

            response = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=messages,
            )
            answer = response.choices[0].message.content

            return Response({
                'question': question,
                'answer': answer,
                'context_used': context_data
            })
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Erreur Groq Assistant IA Admin : {e}")
            import traceback
            return Response({
                'question': getattr(request.data, "get", lambda x, y: "")('question', ''),
                'answer': f"ERREUR BACKEND DÉTECTÉE: {str(e)}",
                'context_used': {}
            }, status=200)

'''

with open(path, 'a', encoding='utf-8') as f:
    f.write(content_to_append)
print("Appended successfully!")
