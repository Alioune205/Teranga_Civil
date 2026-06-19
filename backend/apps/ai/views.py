import logging

from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from drf_spectacular.utils import extend_schema
from .services.document_analyzer import analyze_document
import base64

from .services.gemini_client import analyze_document_with_gemini
from .services.validation_engine import validate_extracted_data
from .validators import validate_citizen_document, check_dossier_duplicate


from .services.pipeline import NdiogoyePipeline

logger = logging.getLogger("apps")


class NdiogoyeChatView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        """
        Endpoint d'interaction avec l'IA Ndiogoye.
        Retourne une réponse JSON simple et synchrone.

        Body attendu:
        {
            "message": "Comment obtenir un extrait de naissance ?",
            "conversation_id": "uuid-de-session"
        }

        Réponse:
        {
            "reply": "...",
            "intent": "INFORM",
            "action": "RESPOND",
            "log_id": "...",      (optionnel)
            "dossier_reference": "..." (optionnel)
        }
        """
        message = request.data.get("message")
        conversation_id = request.data.get("conversation_id")
        image_base64 = request.data.get("image_base64")
        audio_base64 = request.data.get("audio_base64")

        if not message and not audio_base64:
            return Response(
                {"error": "Le champ 'message' est requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not conversation_id:
            return Response(
                {"error": "Le champ 'conversation_id' est obligatoire."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            pipeline = NdiogoyePipeline()
            user = request.user if request.user.is_authenticated else None

            # Fallback for empty text message but valid audio
            if not message and audio_base64:
                message = "[Message vocal]"

            result = pipeline.process_query(message, conversation_id, user, image_base64, audio_base64)
            
            # On génère TOUJOURS la voix de l'assistant (pour la démo / Web)
            if result.get("reply"):
                from .services.tts import generate_wolof_audio_base64
                generated_audio = generate_wolof_audio_base64(result["reply"])
                if generated_audio:
                    result["response_audio_base64"] = generated_audio

            return Response(result, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erreur Ndiogoye IA: {str(e)}", exc_info=True)
            return Response(
                {"reply": "Je rencontre des difficultés techniques. Veuillez réessayer."},
                status=status.HTTP_200_OK,
            )


class NdiogoyeFeedbackView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        log_id = request.data.get("log_id")
        rating = request.data.get("rating")
        comment = request.data.get("comment", "")

        if not log_id or rating is None:
            return Response(
                {"error": "log_id et rating sont requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            from .models import NdiogoyeChatLog

            log = NdiogoyeChatLog.objects.get(id=log_id)
            log.rating = int(rating)
            log.feedback_comment = comment
            log.save()
            return Response({"status": "success"})
        except NdiogoyeChatLog.DoesNotExist:
            return Response(
                {"error": "Log introuvable."}, status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Erreur feedback: {e}")
            return Response(
                {"error": "Erreur serveur."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class AdminAssistantQueryView(APIView):
    """
    Endpoint pour l'assistant IA de l'interface administrateur/superviseur.
    Fournit des analyses et répond aux questions sur les statistiques.
    """
    
    def post(self, request, *args, **kwargs):
        question = request.data.get("question")
        chat_history = request.data.get("chat_history", [])
        
        if not question:
            return Response({"error": "Question manquante."}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            from apps.dossiers.models import Dossier
            from apps.users.models import User
            
            dossier_qs = Dossier.objects.all()
            user_qs = User.objects.filter(role='agent')
            
            if request.user.role in ['civil_admin', 'civil_admin_supervisor'] and request.user.commune:
                dossier_qs = dossier_qs.filter(commune=request.user.commune)
                user_qs = user_qs.filter(commune=request.user.commune)
            
            total_dossiers = dossier_qs.count()
            dossiers_en_attente = dossier_qs.filter(status__in=[Dossier.Status.SUBMITTED, Dossier.Status.DRAFT]).count()
            dossiers_en_traitement = dossier_qs.filter(status=Dossier.Status.IN_REVIEW).count()
            dossiers_termines = dossier_qs.filter(status__in=[Dossier.Status.COMPLETED, Dossier.Status.APPROVED]).count()
            dossiers_rejetes = dossier_qs.filter(status=Dossier.Status.REJECTED).count()
            total_agents = user_qs.count()
            
            context = f"""
Statistiques actuelles du système ({'Globales' if request.user.role == 'super_admin' else f'Commune de {request.user.commune.name}'}) :
- Total des demandes/dossiers : {total_dossiers}
- Demandes en attente : {dossiers_en_attente}
- Demandes en traitement : {dossiers_en_traitement}
- Demandes terminées/approuvées : {dossiers_termines}
- Demandes rejetées : {dossiers_rejetes}
- Nombre total d'agents : {total_agents}
"""

            # Utiliser Groq pour répondre
            from groq import Groq
            from django.conf import settings
            import os
            
            api_key = getattr(settings, 'GROQ_API_KEY', os.environ.get('GROQ_API_KEY'))
            if not api_key:
                return Response(
                    {"error": "L'API IA n'est pas configurée."}, 
                    status=status.HTTP_503_SERVICE_UNAVAILABLE
                )
                
            client = Groq(api_key=api_key)
            
            messages = [
                {
                    "role": "system", 
                    "content": "Tu es l'assistant analytique de la plateforme Teranga Civil. "
                               "Ton rôle est d'analyser les statistiques et de répondre aux questions "
                               "des administrateurs de manière claire et concise. "
                               f"Voici les données actuelles de la plateforme : {context}"
                }
            ]
            
            for msg in chat_history:
                messages.append({"role": msg["role"], "content": msg["content"]})
                
            messages.append({"role": "user", "content": question})
            
            response = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=messages,
                temperature=0.3,
            )
            
            answer = response.choices[0].message.content
            
            return Response({"answer": answer}, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Erreur AdminAssistantQueryView: {e}")
            return Response(
                {"error": "Désolé, je rencontre des difficultés pour analyser les données en ce moment."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class OcrExtractView(APIView):

    """

    Endpoint OCR qui accepte deux modes :

    

    MODE 1 — Upload de fichier (multipart/form-data) :

        POST /api/ai/ocr/extract/

        Body : { "document": <fichier>, "dossier_type": "..." }

    

    MODE 2 — Image caméra en base64 (application/json) :

        POST /api/ai/ocr/extract/

        Body : { "image_base64": "data:image/jpeg;base64,...", "dossier_type": "..." }

    """

    permission_classes = [IsAuthenticated]

    parser_classes = (MultiPartParser, FormParser, JSONParser)



    @extend_schema(tags=['AI & OCR'], summary="Extraire les données d'un document via OCR (upload ou caméra)")

    def post(self, request, *args, **kwargs):

        dossier_type = request.data.get('dossier_type')

        image_base64 = request.data.get('image_base64')

        file_obj = request.FILES.get('document')



        if not file_obj and not image_base64:

            return Response({

                'error': 'Aucun document fourni.',

                'hint': 'Envoyez "document" (fichier) ou "image_base64" (caméra).'

            }, status=400)



        if dossier_type:

            duplicate_check = check_dossier_duplicate(request.user, dossier_type)

            if duplicate_check.get('is_duplicate'):

                return Response({

                    'error': 'Un dossier identique est déjà en cours de traitement.',

                    'details': duplicate_check

                }, status=400)



        # Extraction selon le mode

        if image_base64:

            source = 'camera'

            if ',' in image_base64:

                image_base64 = image_base64.split(',')[1]

            image_data = base64.b64decode(image_base64)

            result = analyze_document(image_data)

        else:

            source = 'upload'

            result = analyze_document(file_obj)



        if result['document_type'] == 'cni' and hasattr(request.user, 'profile'):

            profile_validation = validate_citizen_document(request.user.profile, result['raw_text'])

            result['validation']['profile_match'] = profile_validation



        result['source'] = source

        return Response(result)






class OcrCameraView(APIView):

    """

    Endpoint dédié à la capture caméra (WebRTC).

    """

    permission_classes = [IsAuthenticated]

    parser_classes = (JSONParser,)



    @extend_schema(tags=['AI & OCR'], summary="Extraire les données d'une capture caméra (base64)")

    def post(self, request, *args, **kwargs):

        image_base64 = request.data.get('image_base64')



        if not image_base64:

            return Response({

                'error': 'image_base64 est requis.',

                'hint': 'Envoyez l\'image capturée par la caméra en base64 (data URI ou raw base64).'

            }, status=400)



        if ',' in image_base64:

            image_base64 = image_base64.split(',')[1]

        image_data = base64.b64decode(image_base64)

        

        result = analyze_document(image_data)



        if result['document_type'] == 'cni' and hasattr(request.user, 'profile'):

            profile_validation = validate_citizen_document(request.user.profile, result['raw_text'])

            result['validation']['profile_match'] = profile_validation



        result['source'] = 'camera'

        return Response(result)






class OcrConfirmView(APIView):

    permission_classes = [IsAuthenticated]



    @extend_schema(tags=['AI & OCR'], summary="Confirmer les données extraites d'un document")

    def post(self, request, *args, **kwargs):

        document_id = request.data.get('document_id')

        confirmed_data = request.data.get('confirmed_data')



        if not confirmed_data:

            return Response({'error': 'confirmed_data est requis.'}, status=400)



        return Response({

            'message': 'Données confirmées avec succès.',

            'document_id': document_id,

            'confirmed_data': confirmed_data

        })






