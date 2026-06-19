# Guide d'Intégration Frontend (Flutter) pour Ndiogoye

Ce document liste tout ce que le développeur Flutter (Frontend) doit implémenter de son côté pour que le chatbot Ndiogoye fonctionne parfaitement avec la nouvelle architecture.

## 1. Appel de l'API (Endpoint)

L'endpoint du chatbot est :
`POST /api/ai/ndiogoye/chat/`

L'en-tête (headers) doit inclure :
- `Content-Type: application/json`
- L'authentification (Token JWT) si l'utilisateur est connecté (recommandé pour qu'il puisse vérifier l'état de ses propres dossiers).

## 2. Format de la Requête (Request Body)

La requête envoyée par Flutter doit contenir **absolument** les 3 champs suivants :

```json
{
  "message": "La question tapée par l'utilisateur",
  "chat_history": [
    {"role": "user", "content": "Question précédente"},
    {"role": "assistant", "content": "Réponse précédente"}
  ],
  "conversation_id": "Un identifiant unique pour la session de chat"
}
```

> [!WARNING]
> Le champ `conversation_id` est **obligatoire**. Si ce champ est omis, le serveur va renvoyer une erreur 500 (`IntegrityError: NOT NULL constraint failed: ai_ndiogoyechatlog.session_id`). Le Frontend peut générer un UUID ou utiliser une chaîne aléatoire unique pour chaque session.

## 3. Format de la Réponse (Response Body)

La réponse renvoyée par le serveur (code 200) sera toujours un objet JSON structuré comme ceci :

```json
{
  "intent": "salutation | creer_dossier | suivre_dossier | info_procedure | inconnu",
  "action": "none | start_dossier | check_status",
  "reply": "Le message texte formaté que le bot adresse à l'utilisateur.",
  "conversation_id": "L'identifiant de la session (renvoyé à l'identique)"
}
```

## 4. Logique UI et Navigation (Actions)

C'est ici que le Frontend "donne vie" au chatbot. En fonction de la valeur de `action`, le Frontend doit déclencher des actions spécifiques.

### `action: "none"`
- Affiche simplement le texte contenu dans `reply` dans la bulle de discussion du chatbot.
- Pas d'action particulière.

### `action: "start_dossier"`
- Affiche la réponse de `reply`.
- **Action UI :** Affiche un bouton interactif dans le chat (ex: "Nouvelle Démarche") OU redirige l'utilisateur vers l'écran de création de dossier de l'application.

### `action: "check_status"`
- Affiche la réponse de `reply`.
- **Action UI :** Si le backend n'a pas pu retrouver le dossier dans sa réponse textuelle, le frontend peut afficher un bouton "Suivre mon dossier" qui redirige vers l'écran de suivi où l'utilisateur pourra entrer sa référence (ou afficher un petit widget de saisie de référence dans le chat).

## 5. Gestion des Erreurs et Temps de Réponse

- **Timeouts :** L'API interroge Groq et ChromaDB. Bien que cela soit rapide (~2-5s), le Frontend doit définir un `timeout` suffisant (ex: 20 ou 30 secondes) pour l'appel réseau HTTP.
- **Indicateur de frappe :** Pendant la durée de l'appel HTTP, le Frontend doit impérativement afficher un indicateur de type "Ndiogoye est en train d'écrire..." pour faire patienter l'utilisateur.
- **Code HTTP 500 :** Si jamais le backend renvoie une erreur (ce qui ne devrait plus arriver grâce au système de fallback local), le Frontend doit afficher un message générique chaleureux du type : *"Oups, j'ai eu un petit moment d'absence. Pouvez-vous répéter votre question ?"* plutôt que de crasher ou d'afficher l'erreur brute à l'utilisateur.

## 6. État de l'Intégration Actuelle (Corrections à Apporter par les Devs Frontend)

Suite à l'analyse de la version actuelle du code frontend (`front-mobile-terranga_civil`), voici les ajustements à réaliser d'urgence pour que le chatbot exploite toutes les capacités de l'IA :

1. **Extraction de `intent` et `action` :** Dans `AssistantRemoteDatasource.sendMessage`, seule la valeur de `reply` est extraite et les champs `intent` et `action` sont ignorés (`return reply`). Vous devez impérativement récupérer et retourner ces champs.
2. **Modèle de Message (`MessageModel`) :** Mettez à jour le modèle pour qu'il puisse stocker la valeur de `action` (`none`, `start_dossier`, `check_status`).
3. **Actions interactives dans l'UI :** Dans `AgentChatScreen`, le chatbot se contente d'afficher le texte. Si un message a pour action `start_dossier`, vous devez afficher un bouton "Nouvelle Démarche" qui redirige vers l'écran de création. Si l'action est `check_status`, affichez un bouton "Suivre mon dossier".
4. **Message de Repli (Erreur 500) :** Dans `AssistantNotifier`, le message en cas d'erreur réseau ("Désolé, je ne suis pas disponible...") doit être mis à jour pour correspondre à : *"Oups, j'ai eu un petit moment d'absence. Pouvez-vous répéter votre question ?"*.
