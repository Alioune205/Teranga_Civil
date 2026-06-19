import logging
import re

from apps.dossiers.models import Dossier
from apps.dossiers.serializers import DossierListSerializer

from ..models import NdiogoyeChatLog
from .classifier import IntentClassifier
from .guardrails import Guardrails
from .llm import LLMService
from .retriever import RetrieverService, SemanticCache

logger = logging.getLogger("apps")


class NdiogoyePipeline:
    """
    Orchestrateur central du pipeline IA Ndiogoye (les 5 couches).

    Couche 1 : Guardrails d'entrée
    Couche 2 : Classification d'intention (classifier)
    Couche 3 : RAG - Retrieval (retriever)
    Couche 4 : Raisonnement LLM (llm)
    Couche 5 : Guardrails de sortie + sauvegarde
    """

    def __init__(self):
        self.classifier = IntentClassifier()
        self.retriever = RetrieverService()
        self.llm = LLMService()
        self.guardrails = Guardrails()

    def _build_history(self, session_id: str) -> str:
        """Récupère l'historique récent de la session pour la mémoire conversationnelle."""
        logs = NdiogoyeChatLog.objects.filter(session_id=session_id).order_by(
            "-created_at"
        )[:5]  # 5 derniers échanges
        history = ""
        for log in reversed(logs):
            history += (
                f"Citoyen: {log.user_query}\nNdiogoye: {log.ndiogoye_response}\n\n"
            )
        return history

    def process_query(
        self, query: str, session_id: str, user=None, image_base64: str = None, audio_base64: str = None
    ) -> dict:
        """
        Exécute le pipeline complet et retourne un dictionnaire JSON.
        Toujours retourne un dict avec au minimum un champ 'reply'.
        """
        try:
            # ── 0. Cache Sémantique ────────────────────────────────────────────
            cache = SemanticCache()
            cached_resp = cache.check_cache(query)
            if cached_resp:
                logger.info(f"Cache HIT pour: '{query[:50]}'")
                self._save_log(
                    session_id, query, cached_resp.get("reply", ""), cached_resp.get("intent", "CACHE"), 1.0
                )
                return cached_resp

            # ── 1. Classification d'intention ──────────────────────────────────
            intent = self.classifier.classify(query)
            logger.info(f"Intent classifié: {intent} | Query: '{query[:60]}'")

            # ── 1.5 Traitement spécial GREETING ───────────────────────────────
            if intent == "GREETING":
                user_name = None
                if user and user.is_authenticated:
                    user_name = getattr(user, "first_name", "") or getattr(user, "username", "")
                if user_name:
                    reply = f"Bonjour {user_name} ! Je suis Ndiogoye, votre assistant de l'État Civil du Sénégal 🇸🇳\nComment puis-je vous aider aujourd'hui ?"
                else:
                    reply = "Bonjour ! Je suis Ndiogoye, votre assistant de l'État Civil du Sénégal 🇸🇳\nComment puis-je vous aider aujourd'hui ?"
                self._save_log(session_id, query, reply, intent, 1.0)
                return {"reply": reply, "intent": intent, "action": "RESPOND"}

            # ── 1.6 Suivi de dossier ───────────────────────────────────────────
            if intent == "TRACK_DOSSIER":
                match = re.search(r"(DOS-[A-Z0-9]+)", query, re.IGNORECASE)
                if match:
                    reference = match.group(1).upper()
                    dossier = Dossier.objects.filter(reference=reference).first()
                    if dossier:
                        reply = (
                            f"Voici l'état de votre dossier **{reference}** "
                            f"({dossier.get_type_display()}) :\n"
                            f"Statut actuel : **{dossier.get_status_display()}**."
                        )
                    else:
                        reply = (
                            f"Je ne trouve aucun dossier avec la référence **{reference}** "
                            f"dans notre système. Vérifiez bien la référence ou contactez votre mairie."
                        )
                    self._save_log(session_id, query, reply, intent, 1.0)
                    return {"reply": reply, "intent": intent, "action": "RESPOND"}
                else:
                    if user and user.is_authenticated:
                        dossiers = Dossier.objects.filter(citizen=user)
                        count = dossiers.count()
                        if count == 0:
                            reply = "Vous n'avez actuellement aucun dossier en cours dans notre système."
                        elif count == 1:
                            d = dossiers.first()
                            reply = (
                                f"J'ai trouvé votre dossier **{d.reference}** "
                                f"({d.get_type_display()}).\n"
                                f"Son statut actuel est : **{d.get_status_display()}**."
                            )
                        else:
                            refs = [
                                f"• **{d.reference}** — {d.get_type_display()} ({d.get_status_display()})"
                                for d in dossiers
                            ]
                            reply = (
                                "Vous avez plusieurs dossiers en cours :\n"
                                + "\n".join(refs)
                                + "\n\nLequel souhaitez-vous suivre ?"
                            )
                        self._save_log(session_id, query, reply, intent, 1.0)
                        return {"reply": reply, "intent": intent, "action": "RESPOND"}
                    else:
                        reply = (
                            "Pour vérifier l'état de votre dossier, "
                            "veuillez me fournir sa **référence exacte** (ex: DOS-123456)."
                        )
                        self._save_log(session_id, query, reply, intent, 1.0)
                        return {"reply": reply, "intent": intent, "action": "CLARIFY"}

            # ── 2. RAG — Retrieval ─────────────────────────────────────────────
            context = ""
            if intent in ["INFORM", "DIAGNOSE", "GUIDE", "EMERGENCY"]:
                context = self.retriever.retrieve_context(query)

            # ── 3. Historique conversationnel ──────────────────────────────────
            history = self._build_history(session_id)

            # ── Personnalisation par le prénom ─────────────────────────────────
            user_name = None
            if user and user.is_authenticated:
                user_name = getattr(user, "first_name", "") or getattr(user, "username", "")

            # ── 4. LLM — Raisonnement Gemini ───────────────────────────────────
            action = "RESPOND"
            dossier_ref = None
            func_call_final = None
            full_response = ""

            for chunk_text, func_call in self.llm.generate_response_stream(
                intent, query, context, history, image_base64, audio_base64, user_name
            ):
                if chunk_text:
                    full_response += chunk_text
                if func_call:
                    func_call_final = func_call

            # ── 5. Guardrails de sortie ────────────────────────────────────────
            full_response = self.guardrails.check_response(full_response, context)

            # ── 5.5 Function Calling — Création dossier + paiement ────────────
            if func_call_final:
                action = "SHOW_PAYMENT_AND_DOSSIER"
                from apps.communes.models import Commune

                commune = Commune.objects.first()
                d_type = (
                    Dossier.Type.BIRTH_CERTIFICATE
                    if any(w in query.lower() for w in ["naissance", "né", "nee", "acte"])
                    else Dossier.Type.OTHER
                )
                dossier = Dossier.objects.create(
                    type=d_type,
                    status=Dossier.Status.SUBMITTED,
                    commune=commune,
                    citizen=user if user and user.is_authenticated else None,
                    metadata={
                        "source": "chatbot_ndiogoye",
                        "type_demarche": func_call_final.get("type_demarche", ""),
                        "tarif": func_call_final.get("tarif", 500),
                        "numero_acte": func_call_final.get("numero_acte", ""),
                        "annee": func_call_final.get("annee", ""),
                    },
                )
                dossier_ref = dossier.reference
                dossier_data = DossierListSerializer(dossier).data
                logger.info(f"Dossier créé via chatbot: {dossier_ref}")

            # ── Sauvegarde historique ──────────────────────────────────────────
            log_id = self._save_log(session_id, query, full_response, intent, 0.9)

            # ── Mise en cache sémantique ───────────────────────────────────────
            if not dossier_ref and action == "RESPOND" and full_response:
                cache.add_to_cache(
                    query,
                    {"reply": full_response, "intent": intent, "action": action},
                )

            # ── Réponse finale ─────────────────────────────────────────────────
            response_data = {
                "reply": full_response,
                "intent": intent,
                "action": action,
            }
            if dossier_ref:
                response_data["dossier_reference"] = dossier_ref
                response_data["dossier_data"] = dossier_data
            if log_id:
                response_data["log_id"] = str(log_id)

            return response_data

        except Exception as e:
            logger.error(f"Pipeline error: {e}", exc_info=True)
            return {
                "reply": "J'ai rencontré une difficulté technique. Veuillez réessayer dans un instant.",
                "intent": "FALLBACK",
                "action": "FALLBACK",
            }

    def _save_log(self, session_id, user_query, response, intent, score):
        try:
            log = NdiogoyeChatLog.objects.create(
                session_id=session_id,
                user_query=user_query,
                ndiogoye_response=response,
                intent=intent,
                confidence_score=score,
            )
            return log.id
        except Exception as e:
            logger.error(f"Erreur sauvegarde historique: {e}")
            return None
