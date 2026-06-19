import re


class IntentClassifier:
    """
    Couche 2: Classification d'intention (Heuristique rapide avant RAG).
    Intentions: GREETING, TRACK_DOSSIER, EMERGENCY, INFORM, DIAGNOSE, GUIDE, OUT_OF_SCOPE
    """

    # Documents officiels connus — une demande explicite de ces docs = INFORM
    DOCUMENTS_CONNUS = [
        "acte de naissance", "bulletin de naissance", "extrait de naissance",
        "copie littérale", "certificat de naissance", "certificat de vie",
        "certificat de résidence", "certificat de célibat", "certificat de mariage",
        "certificat de décès", "certificat d'hérédité", "certificat de bonne vie",
        "permis d'inhumation", "jugement de divorce", "mutation de parcelle",
        "autorisation de construire", "pv de vérification", "extrait", "bulletin",
        "certificat", "acte", "copie", "permis", "jugement", "attestation",
    ]

    def classify(self, query: str) -> str:
        q_lower = query.lower().strip()

        # 0. Salutations simples
        if re.search(
            r"^\s*(bonjour|salut|hello|bonsoir|coucou|salam|allo|allô|na nga def|nuyu|ba beneen|merci|au revoir|à bientôt)\s*$",
            q_lower,
        ):
            return "GREETING"

        if re.search(
            r"\b(bonjour|salut|hello|bonsoir|coucou|salam|na nga def|nuyu)\b",
            q_lower,
        ) and len(q_lower.split()) <= 5:
            return "GREETING"

        # 1. Suivi de dossier
        if re.search(
            r"\b(suivre|suivi|etat|état|avancement|dos-|ou en est|reference|référence|ma demande|mon dossier|statut)\b",
            q_lower,
        ):
            return "TRACK_DOSSIER"

        # 2. Urgence (décès très récent, situation critique)
        if re.search(
            r"\b(mort|décédé|décédée|deces|décès|urgence|vient de|il vient|elle vient|enterrement|inhumation|hier|ce matin)\b",
            q_lower,
        ):
            return "EMERGENCY"

        # 3. Demande EXPLICITE d'un document connu → INFORM directement
        #    ex: "je veux un extrait de naissance", "j'ai besoin d'un certificat de mariage"
        #    Ces cas NE DOIVENT PAS aller en DIAGNOSE — le doc est connu, on liste les pièces
        for doc in self.DOCUMENTS_CONNUS:
            if doc in q_lower:
                return "INFORM"

        # 4. Demande d'information générale (comment, combien, délai, prix, documents)
        if re.search(
            r"\b(comment|combien|delai|délai|prix|tarif|frais|coût|pieces|pièces|documents?|faut-il|faut il|papier|liste|quoi|qu'est-ce|c'est quoi|qu'il faut|nécessaire|requis|obtenir|avoir|faire|procedure|procédure)\b",
            q_lower,
        ):
            return "INFORM"

        # 5. Diagnostic de situation complexe (l'utilisateur ne sait pas ce dont il a besoin)
        #    ex: "que faire si mon père est décédé", "je ne sais pas quoi faire", "ma situation est compliquée"
        if re.search(
            r"\b(que faire|je ne sais pas|je suis perdu|ma situation|problème|compliqué|cas particulier|je suis né|mon père|ma mère|je veux savoir|besoin d'aide)\b",
            q_lower,
        ):
            return "DIAGNOSE"

        # 6. Guide étape par étape
        if re.search(
            r"\b(etape|étape|demarche|démarche|par où|commencer|débuter|guide|comment faire)\b",
            q_lower,
        ):
            return "GUIDE"

        # Par défaut → info générale
        return "INFORM"
