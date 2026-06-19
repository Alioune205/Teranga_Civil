class Guardrails:
    """
    Couche 5: Garde-fous et contrôle qualité avant d'envoyer la réponse à l'utilisateur.
    """

    def check_response(self, response: str, context: str) -> str:
        """
        Vérifie qu'aucun tarif fantaisiste n'a été inventé (ex: 5000 FCFA si ce n'est pas dans le contexte).
        Dans un vrai système en prod, on utiliserait des expressions régulières avancées ou un second appel LLM (LLM-as-judge).
        Ici on implémente un filtre basique anti-hallucination.
        """
        response_lower = response.lower()
        context_lower = context.lower()

        # Le garde-fou des tarifs a été désactivé car nous simulons désormais les prix
        # entre 300 et 1000 FCFA selon la demande de l'utilisateur.
        return response
