import unittest
import os
from unittest.mock import patch

# Setup minimum de Django pour les imports si nécessaire
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

from apps.ai.faq import find_closest_faq, FLAT_FAQ
from apps.ai.ndiogoye import process_ndiogoye_chat

class TestNdiogoyeFAQFirst(unittest.TestCase):

    def test_faq_exact_match(self):
        """Vérifie qu'une question connue renvoie la bonne réponse de base de la FAQ (score > 65)."""
        question = "comment obtenir un extrait de naissance ?"
        # On teste directement la couche FAQ
        reponse_faq = find_closest_faq(question, threshold=65.0)
        self.assertIn("certificat médical d'accouchement", reponse_faq)
        self.assertIn("pièce d'identité", reponse_faq)

    def test_faq_fuzzy_match(self):
        """Vérifie que RapidFuzz trouve la bonne intention même avec des fautes (score > 65)."""
        question = "cmt avoir 1 extrt de naissance stp ?"
        reponse_faq = find_closest_faq(question, threshold=65.0)
        self.assertIn("certificat médical", reponse_faq)

    def test_faq_below_threshold_fallback(self):
        """Vérifie que Ndiogoye refuse de répondre aux questions hors-sujet ou inconnues (score < 65)."""
        question = "Quelle est la recette du poulet yassa ?"
        reponse = process_ndiogoye_chat(question)
        
        self.assertEqual(
            reponse['reply'], 
            "Je ne dispose pas de cette information. Veuillez consulter un agent d'état civil.",
            "L'IA a généré une réponse libre ou a échoué à utiliser le fallback strict."
        )

    def test_faq_llm_reformulation_no_hallucination(self):
        """
        Vérifie que l'appel global (incluant le LLM) n'invente pas de nouvelles pièces ou procédures.
        (Nécessite la clé API Groq pour tester le LLM réel).
        """
        question = "comment obtenir un acte de mariage ?"
        reponse = process_ndiogoye_chat(question)
        
        # Le LLM ne doit faire que reformuler la réponse de la FAQ.
        # On vérifie que les mots-clés de base y sont bien.
        reponse_lower = reponse['reply'].lower()
        self.assertTrue(
            "certificat de célébration" in reponse_lower or "célébration" in reponse_lower,
            "Le LLM a oublié l'information critique de la FAQ."
        )
        # Vérifions qu'il n'invente pas de frais par exemple :
        self.assertNotIn("cfa", reponse_lower, "Le LLM a inventé un tarif !")

    @patch('apps.ai.ndiogoye.client', None)
    def test_fallback_when_llm_is_down(self):
        """Vérifie que si l'API IA est indisponible, Ndiogoye renvoie la réponse FAQ brute stricte."""
        question = "documents pour décès"
        reponse = process_ndiogoye_chat(question)
        
        self.assertEqual(
            reponse['reply'], 
            "L'acte de décès nécessite le certificat médical de constatation du décès et le livret de famille ou la pièce d'identité du défunt.",
            "La réponse brute n'a pas été renvoyée quand le LLM est hors-ligne."
        )

if __name__ == '__main__':
    unittest.main()
