# Guide d'Intégration Frontend : Ndiogoye IA (Gemini 2.5 Flash)

Ce document décrit comment l'équipe Frontend doit intégrer le chatbot Ndiogoye dans l'interface utilisateur de **Teranga Civil**. 
Le backend IA a été entièrement refait, sécurisé, et propulsé par Gemini 2.5 Flash avec RAG (Retrieval-Augmented Generation) et un système natif de suivi de dossiers.

## 1. Endpoint API

L'unique point d'entrée pour communiquer avec Ndiogoye est la route POST suivante :

```http
POST /api/ai/ndiogoye/chat/
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>
```

> **Note :** L'authentification par JWT est requise car l'historique conversationnel est sauvegardé côté backend pour chaque session.

## 2. Payload Attendue (Request)

L'API attend un objet JSON avec le message de l'utilisateur et un identifiant de session unique.

```json
{
  "message": "Bonjour Ndiogoye",
  "conversation_id": "session-xyz-123",
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAA...", // Optionnel: Envoyez l'image en base64
  "audio_base64": "UklGRiQAAABXQVZFZm10IBAAAAABAAEA..." // Optionnel: Envoyez le fichier audio (.m4a ou .wav) en base64
}
```

### Paramètres
* `message` (string, **requis**) : Le texte envoyé par l'utilisateur. S'il envoie uniquement un vocal, envoyez une chaîne vide `""`.
* `conversation_id` (string, **requis**) : L'identifiant unique de la session pour maintenir l'historique (ex: un UUID ou le token utilisateur).
* `image_base64` (string, *optionnel*) : L'image encodée en base64. Idéal si l'utilisateur prend en photo un document. Ndiogoye lira le document.
* `audio_base64` (string, *optionnel*) : Le fichier audio encodé en base64. Ndiogoye l'écoutera (Speech-to-Text natif côté backend Gemini).

## 3. Structure de la Réponse

L'API renvoie une réponse JSON simple et **synchrone** (pas de SSE).

**Exemple de réponse réussie :**
```json
{
    "reply": "Bonjour Amadou ! Pour votre extrait de naissance, voici ce qu'il vous faut : ...",
    "intent": "INFORM",
    "action": "RESPOND",
    "log_id": "uuid-1234",
    "dossier_reference": "DOS-9876" // Présent uniquement si action = SHOW_PAYMENT_AND_DOSSIER
}
```

### Champs de la Réponse
1. **`reply`** (string) : Le message complet généré par Ndiogoye (formaté en Markdown).
2. **`intent`** (string) : L'intention détectée (ex: `INFORM`, `GREETING`).
3. **`action`** (string) : L'action à effectuer par l'interface Flutter :
   * `RESPOND` : Simplement afficher le texte dans la bulle de chat.
   * `SHOW_PAYMENT_AND_DOSSIER` : Afficher les boutons Wave/Orange Money et le bouton "Voir dossier".
   * `FALLBACK` : Afficher un message d'erreur.
4. **`dossier_reference`** (string, *optionnel*) : Référence du dossier créé.
5. **`log_id`** (string, *optionnel*) : Identifiant du log pour envoyer un feedback.

## 4. Endpoint de Feedback

Pour améliorer l'IA, l'utilisateur peut noter une réponse.

**URL** : `POST /api/ai/ndiogoye/feedback/`

**Payload :**
```json
{
  "log_id": "123e4567-e89b-12d3-a456-426614174000",
  "rating": 1, // 1 pour positif, -1 pour négatif
  "comment": "Très rapide merci !" // Optionnel
}
```

## 5. Recommandations d'Intégration pour l'Équipe Flutter (Best Practices)

Pour intégrer Ndiogoye de manière optimale, voici la marche à suivre recommandée pas à pas :

### Étape 1 : Gérer la Requête (JSON Synchrone)
Effectuez une requête HTTP `POST` standard en utilisant Dio ou http. Le backend renverra une réponse JSON complète.
*   **Logique de l'UI :** Pendant l'attente de la réponse, affichez un indicateur de chargement (`_TypingIndicator`) dans la zone de chat. Affichez la réponse une fois reçue. L'effet "machine à écrire" simulé côté frontend n'est pas nécessaire, mais peut être fait artificiellement si vous souhaitez l'animation.

### Étape 2 : Formatage Markdown
Les réponses de Gemini contiennent du Markdown (titres, puces, gras).
*   **Package recommandé :** [`flutter_markdown`](https://pub.dev/packages/flutter_markdown).
*   Enveloppez le texte reçu dans un widget `MarkdownBody` pour qu'il soit propre et lisible.

### Étape 3 : Médias (Images et Audio)
L'interface de chat doit permettre d'envoyer des pièces jointes et des messages vocaux. Ndiogoye est multimodal.
*   **Image :** Utilisez [`image_picker`](https://pub.dev/packages/image_picker) pour prendre une photo. Convertissez-la en Base64 (`base64Encode(bytes)`) et mettez-la dans le champ `image_base64`.
*   **Audio (Vocal) :** Utilisez un package comme [`record`](https://pub.dev/packages/record) pour enregistrer la voix de l'utilisateur en `.m4a` ou `.wav`. Convertissez le fichier généré en Base64 et envoyez-le dans le champ `audio_base64`. Ndiogoye comprendra le vocal.
*   **Astuce :** Compressez légèrement l'image avant encodage.

### Étape 4 : Le système de Feedback
À la réception de la réponse, récupérez le `log_id`.
*   Affichez deux petits boutons discrets (👍 et 👎) sous la bulle du message.
*   Si le citoyen clique, faites un appel asynchrone (en arrière-plan, sans bloquer l'UI) vers l'endpoint `/api/ai/ndiogoye/feedback/`.
*   Une fois cliqué, colorisez le pouce ou cachez les boutons pour indiquer que le vote est pris en compte.

### Étape 5 : Les Boutons d'Action (Paiement)
Quand le chunk final contient `"action": "SHOW_PAYMENT_AND_DOSSIER"`, l'IA a fini son travail.
*   Affichez des boutons clairs pour Wave et Orange Money.
*   Stockez la `dossier_reference` pour pouvoir rediriger le citoyen vers la page de suivi une fois le paiement validé.

## 4. Fonctionnalité Spéciale : Suivi de Dossier

Le backend intègre une fonctionnalité autonome pour le suivi de dossier.
**Il n'y a plus besoin de rediriger le citoyen vers la mairie pour le suivi de dossier !**

Le comportement côté backend est le suivant :
- Si l'utilisateur demande "Je veux suivre mon dossier" : Ndiogoye renverra une action `CLARIFY` avec le texte *"Veuillez me fournir votre référence exacte (ex: DOS-123456)"*.
- Si l'utilisateur tape "Où en est mon dossier DOS-98765" : Ndiogoye interrogera la base de données et renverra directement son statut formel, par exemple : *"Le statut de votre dossier est : En cours de vérification."*

Le frontend n'a rien à programmer de particulier pour cela, le backend s'occupe de renvoyer le texte final dans `reply`.

## 5. Création de dossier & Paiement Intégré

Ndiogoye est programmé pour demander à l'utilisateur des informations (ex: numéro d'acte, année). 
Dès que l'utilisateur fournit les informations requises, Ndiogoye :
1. Estime le tarif (entre 300 et 1000 FCFA).
2. Le backend crée **automatiquement** le dossier en base de données.
3. L'API renvoie l'action `SHOW_PAYMENT_AND_DOSSIER` avec le champ `dossier_reference`.

**Ce que l'équipe Frontend doit faire à la réception de `SHOW_PAYMENT_AND_DOSSIER` :**
- Afficher la réponse texte de Ndiogoye (qui annoncera le prix simulé).
- Afficher en dessous de la bulle de chat des boutons de paiement (Wave, Orange Money).
- Afficher un bouton "Voir le dossier" qui redirige l'utilisateur vers la page de détail du dossier en utilisant la `dossier_reference` fournie.

## 6. Gestion des États UI Recommandée

* **Loading State :** Affichez un indicateur "Ndiogoye est en train de réfléchir..." (typing indicator) dès l'envoi de la requête.
* **Markdown :** L'IA génère souvent du Markdown (ex: les `**` pour le gras). Comme vous êtes sur Flutter, utilisez le package officiel `flutter_markdown` pour que le texte s'affiche correctement (gras, listes à puces) au lieu d'afficher des astérisques.
* **Erreurs (HTTP 400 / 500) :** Si l'API renvoie une erreur, affichez "Ndiogoye est actuellement indisponible, veuillez réessayer plus tard."
