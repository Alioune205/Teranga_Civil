import logging

from django.conf import settings
from google import genai

logger = logging.getLogger("apps")


class LLMService:
    """
    Couche 4: Raisonnement LLM utilisant Gemini 2.5 Flash via google-genai.
    """

    def __init__(self):
        api_key = getattr(settings, "GEMINI_API_KEY", None)
        if not api_key:
            logger.error("GEMINI_API_KEY manquante dans les settings.")
        self.client = genai.Client(api_key=api_key)
        self.model_name = "gemini-2.5-flash"

    def generate_response_stream(
        self,
        intent: str,
        query: str,
        context: str,
        history: str,
        image_base64: str = None,
        audio_base64: str = None,
        user_name: str = None,
    ):
        """
        Construit le prompt systémique complet et fait l'appel au LLM.
        """

        # ── Arbre de décision (uniquement pour situations complexes) ───────────
        decision_tree_prompt = ""
        if intent in ["DIAGNOSE", "GUIDE", "EMERGENCY"]:
            decision_tree_prompt = """
[MODE DIAGNOSTIC ACTIVÉ — SITUATION COMPLEXE]
L'utilisateur ne sait pas exactement ce dont il a besoin. Tu dois l'aider à identifier la bonne démarche.
— S'il te manque une information clé (lieu de naissance, situation familiale, nationalité, etc.), pose UNE SEULE question très ciblée.
— Si la situation est claire, guide-le étape par étape : une étape à la fois, attends sa confirmation avant de passer à la suivante.
— Montre de l'empathie si la situation est difficile (deuil, urgence).
"""

        # ── Détection de re-salutation depuis l'historique ─────────────────────
        already_greeted = bool(history and len(history.strip()) > 10)
        no_regreeting_rule = ""
        if already_greeted:
            no_regreeting_rule = """
⛔ RÈGLE ABSOLUE ANTI-RÉPÉTITION :
L'historique prouve que tu as DÉJÀ salué le citoyen. Tu NE DOIS PAS, sous AUCUN prétexte,
commencer ta réponse par "Bonjour", "Salut", "Bonsoir" ou toute autre formule de salutation.
Commence IMMÉDIATEMENT avec l'information demandée, sans aucune introduction.
Violer cette règle est une erreur critique.
"""

        # ── Personnalisation prénom ─────────────────────────────────────────────
        prenom_rule = ""
        if user_name:
            prenom_rule = f"""
Le citoyen s'appelle {user_name}. Utilise son prénom de façon naturelle et chaleureuse dans ta réponse
(ex : "Voici ce qu'il vous faut, {user_name} :", ou "Bien sûr {user_name},").
Fais-le UNE seule fois par réponse, de manière fluide — jamais de façon mécanique.
"""

        # ── Prompt complet ─────────────────────────────────────────────────────
        system_prompt = f"""Tu es Ndiogoye, l'assistant virtuel de l'État Civil du Sénégal, la fierté technologique du pays.
Tu incarnes la vraie "Téranga" sénégalaise : tu es extrêmement poli, chaleureux, rassurant et dévoué.

════════════════════════════════════════════
PERSONNALITÉ ET TON (COMMENT TU DOIS PARLER)
════════════════════════════════════════════
• Sois naturel, fluide et très humain (comme le meilleur des réceptionnistes).
• N'utilise pas un ton froid ou robotique de l'administration classique.
• Utilise de petites expressions chaleureuses au début ou à la fin de tes phrases (ex: "C'est un plaisir de vous accompagner", "Soyez rassuré", "Je m'en occupe avec grand plaisir").
• Montre-toi proactif : anticipe les besoins du citoyen et guide-le pas à pas sans le brusquer.
• Si la situation s'y prête, n'hésite pas à être un peu bavard pour mettre le citoyen à l'aise, tout en restant toujours professionnel.

{no_regreeting_rule}

{prenom_rule}

════════════════════════════════════════════
TES CAPACITÉS (Tu peux traiter TOUS ces 28 documents)
════════════════════════════════════════════
1. Acte, Bulletin, Extrait et Copie littérale de naissance, Certificat de non-inscription, Déclaration de naissance.
2. Certificats de vie (individuel, collectif), Prise en charge familiale, Résidence, Célibat.
3. Mariage (Sénégalais, Étrangers), Non-inscription de mariage, Copie littérale, Jugement de divorce, Non-divorce/remariage/séparation.
4. Décès (Certificat, Bulletin, Permis d'inhumation, Non-inscription), Hérédité.
5. Foncier & Urbanisme (PV vérification, Régularisation, Autorisation construire, Mutation parcelle).
6. Certificat de bonne vie et mœurs.
Si le citoyen demande ce que tu peux faire, donne-lui un aperçu global ou propose-lui de l'aider selon sa situation (naissance, décès, mariage, foncier).

════════════════════════════════════════════
FORMATAGE — RÈGLES OBLIGATOIRES ET INVIOLABLES
════════════════════════════════════════════

1. LISTES DE DOCUMENTS : Utilise TOUJOURS des puces (•) pour lister les documents/pièces.
   Exemple correct :
   • Numéro de l'acte dans le registre
   • Année de déclaration
   • Nom et prénom du titulaire

2. INFORMATIONS IMPORTANTES : Mets en **gras** les délais, validités, tarifs et statuts.
   Exemple : Validité : **3 mois** | Délai : **1 an après la naissance**

1. LORS D'UNE DEMANDE PRÉCISE MAIS AMBIGUË :
   Si ta base de connaissances te remonte plusieurs procédures très similaires (ex: Extrait de naissance ET Déclaration de naissance), **NE LISTE PAS TOUT EN MÊME TEMPS**. Demande poliment au citoyen de préciser ce qu'il veut exactement (ex: "Souhaitez-vous déclarer une nouvelle naissance ou obtenir la copie d'un acte déjà existant ?").

2. LORS D'UNE DEMANDE CLAIRE ET PRÉCISE (Ex: "Je veux un certificat de naissance") :
   ① Confirme le document avec enthousiasme.
   ② Liste TOUTES les pièces requises avec des puces (•).
   ③ Indique le délai de délivrance et la validité en **gras**.
   ④ Indique le coût estimé (simule un prix entre 300 et 1000 FCFA).
   ⑤ Propose immédiatement de démarrer en collectant les infos.

2. LORS D'UNE CONVERSATION GÉNÉRALE OU DE QUESTIONS (Ex: "Que fais-tu ?") :
   ① Sois naturel, bavard et amical.
   ② Liste quelques catégories de documents que tu gères sans être un robot.
   ③ Demande comment tu peux aider spécifiquement aujourd'hui.

════════════════════════════════════════════
MISSION PRINCIPALE — LANCER LES DÉMARCHES EN LIGNE
════════════════════════════════════════════

⚡ APRÈS avoir fourni le résumé structuré du document (pièces, délai, prix), tu dois :
1. Demander au citoyen de fournir les informations nécessaires (numéro d'acte, année, nom, etc.). Tu peux les demander en une seule fois ou étape par étape selon ce qui te semble le plus naturel.
2. Une fois TOUTES les infos collectées au fil de la discussion, appeler OBLIGATOIREMENT la fonction `creer_dossier_paiement`.
3. Après l'appel de la fonction, rassurer le citoyen avec une phrase courte.

Exemple de flux :
— Citoyen: "Je veux un extrait de naissance"
— Ndiogoye: Liste les pièces, délai, et annonce 500 FCFA. "Voulez-vous qu'on démarre ? Quel est votre numéro d'acte ?"
— Citoyen: Donne son numéro. Ndiogoye demande l'année. etc.
— Une fois complet, Ndiogoye appelle `creer_dossier_paiement` -> "Dossier créé !"


{decision_tree_prompt}

════════════════════════════════════════════
RÈGLES ABSOLUES (jamais violer)
════════════════════════════════════════════
• Ne JAMAIS inventer un tarif non documenté (sauf pour simuler le paiement)
• Ne JAMAIS décrire une procédure inexistante
• Ne JAMAIS inventer d'articles de loi
• Si le délai n'est pas précisé dans le texte, **ne dis pas que tu ne sais pas**. Simule un délai standard et réaliste (ex: 24h à 48h).
• Si une info critique est introuvable → oriente vers la mairie avec empathie
• Ne JAMAIS donner de conseils médicaux ou juridiques
• TRÈS IMPORTANT : "Certificat de naissance" et "Extrait de naissance" désignent EXACTEMENT le même document. Traite-les de la même manière.

════════════════════════════════════════════
CONTEXTE OFFICIEL (base de connaissances RAG)
════════════════════════════════════════════
{context if context else "Aucun contexte RAG spécifique. Réponds sur la base de tes connaissances générales de l'état civil sénégalais."}

════════════════════════════════════════════
HISTORIQUE DE LA SESSION (mémoire conversationnelle)
════════════════════════════════════════════
{history if history else "Début de la conversation — première interaction."}

INTENTION CLASSIFIÉE : {intent}
MESSAGE DU CITOYEN : {query}
"""

        # ── Définition de la fonction de paiement (Function Calling) ──────────
        def creer_dossier_paiement(
            type_demarche: str, tarif: int, numero_acte: str = "", annee: str = ""
        ):
            """
            Crée un dossier administratif et initie le paiement en ligne.
            Appelle cette fonction UNIQUEMENT une fois que le citoyen a fourni TOUTES
            les informations nécessaires pour son type de démarche.

            Args:
                type_demarche: Type exact de document (ex: "extrait de naissance")
                tarif: Frais en FCFA entre 300 et 1000
                numero_acte: Numéro de l'acte dans le registre (si fourni)
                annee: Année de déclaration (si fournie)
            """
            pass

        try:
            import base64

            contents = [system_prompt]

            # Gestion image (Vision)
            if image_base64:
                try:
                    if "," in image_base64:
                        image_base64 = image_base64.split(",", 1)[1]
                    image_bytes = base64.b64decode(image_base64)
                    contents.append(
                        genai.types.Part.from_bytes(
                            data=image_bytes, mime_type="image/jpeg"
                        )
                    )
                    logger.info("Image ajoutée au prompt Gemini (mode Vision).")
                except Exception as e:
                    logger.error(f"Erreur décodage image: {e}")

            # Gestion audio (Vocal)
            if audio_base64:
                try:
                    if "," in audio_base64:
                        audio_base64 = audio_base64.split(",", 1)[1]
                    audio_bytes = base64.b64decode(audio_base64)
                    contents.append(
                        genai.types.Part.from_bytes(
                            data=audio_bytes, mime_type="audio/mp4" # Gemini gère bien le mp4/m4a
                        )
                    )
                    logger.info("Fichier audio ajouté au prompt Gemini.")
                except Exception as e:
                    logger.error(f"Erreur décodage audio: {e}")

            response_stream = self.client.models.generate_content_stream(
                model=self.model_name,
                contents=contents,
                config=genai.types.GenerateContentConfig(
                    temperature=0.7,
                    tools=[creer_dossier_paiement],
                ),
            )

            func_call_args = None
            has_yielded_text = False

            for chunk in response_stream:
                if chunk.function_calls:
                    fc = chunk.function_calls[0]
                    func_call_args = fc.args
                    logger.info(f"Function call: {fc.name} | {fc.args}")

                if chunk.text:
                    has_yielded_text = True
                    yield chunk.text, func_call_args

            # Si function call sans texte
            if func_call_args and not has_yielded_text:
                tarif = func_call_args.get("tarif", 500)
                type_d = func_call_args.get("type_demarche", "votre démarche")
                yield (
                    f"Parfait ! Votre dossier pour **{type_d}** a bien été enregistré. "
                    f"Les frais de traitement s'élèvent à **{tarif} FCFA**. "
                    f"Procédez au paiement ci-dessous pour finaliser 👇",
                    func_call_args,
                )

        except Exception as e:
            logger.error(f"Erreur appel Gemini: {e}")
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                yield (
                    "Il y a beaucoup de monde au guichet virtuel en ce moment ! "
                    "Pouvez-vous patienter ~1 minute et reposer votre question ? 🙏",
                    None,
                )
            elif "503" in str(e) or "UNAVAILABLE" in str(e):
                yield (
                    "Le service est temporairement surchargé. "
                    "Réessayez dans quelques instants, je suis là pour vous ! 🙂",
                    None,
                )
            else:
                logger.error(f"Erreur Gemini inattendue", exc_info=True)
                yield (
                    "J'ai rencontré un problème technique. Réessayez ou contactez votre mairie directement.",
                    None,
                )
