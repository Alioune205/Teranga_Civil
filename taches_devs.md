# 📋 Répartition des Tâches Détaillées

Suite aux derniers ajustements, voici la répartition mise à jour des tâches pour les différents développeurs :

---

## 🔧 DEV 1A — Lansana Coly · Backend Core + IA Pure
> **Rôle :** Responsable du cœur backend et de toute l'intelligence artificielle (Chatbot Ndiogoye).

**Tâches :**
1. ~~**Système OTP** : Vérification par téléphone ou email (envoi et validation).~~ ✅ **FAIT (Envoi mail implémenté)**
2. ~~**Login unifié** : Connexion par téléphone ou email.~~ ✅ **FAIT**
3. ~~**Throttling anti brute-force** : Limite de requêtes sur le login.~~ ✅ **FAIT (ScopedRateThrottle appliqué)**
4. ~~**Demande tierce personne** : Permettre les demandes pour d'autres citoyens (père, mère, enfant).~~ ✅ **FAIT**
5. ~~**Historique des connexions** : Traçabilité des logins avec IP et User-Agent.~~ ✅ **FAIT**
6. ~~**Ndiogoye IA (Chatbot)** : **Tu as désormais l'exclusivité totale sur la partie IA**. Intégration du Chatbot et gestion des intentions (salutation, créer dossier, etc.).~~ ✅ **FAIT (Intégration Groq LLM avec Tool Calling JSON finalisée)** 

---

## 🤖 DEV 1D — Kalz Le Frimeur · OCR Exclusif
> **Rôle :** Responsable exclusif de l'extraction de texte (OCR). Aucune implication dans l'IA générale.

**Tâches :**
1. ~~**Extraction structurée OCR** : Parser les données des CNI avec Tesseract.~~ ✅ **FAIT (Migration vers EasyOCR accomplie avec succès)**
2. ~~**Pré-traitement d'image** : Nettoyage et amélioration du contraste/netteté avant OCR.~~ ✅ **FAIT**
3. ~~**Endpoints de confirmation OCR** : Extraction brute et validation manuelle par l'utilisateur.~~ ✅ **FAIT**
4. ~~**Détection de doublons** : Par hachage de fichiers (SHA256).~~ ✅ **FAIT**

*(Toutes les tâches de DEV 1D sont officiellement terminées ! 🎉)*

---

## 💻 DEV 2A — Pape Alioune Sène · Dashboards Administratifs Web (React)
> **Rôle :** Responsable uniquement des interfaces administratives Web pour les agents et administrateurs. **Ne gère aucune partie mobile/citoyen.**

**Tâches :**
1. ~~**Architecture Web React** : Poursuivre le développement avec TailwindCSS et ShadCN.~~ ✅ **FAIT**
2. ~~**Dashboard Super Admin** : Vue globale, gestion des paiements et suivi des Audit Logs.~~ ✅ **FAIT**
3. ~~**Dashboard Officier d'État Civil** : Tableau de bord dédié avec Datatables, validation des dossiers.~~ ✅ **FAIT**
4. ~~**Supervision Ndiogoye** : Interface d'historique des requêtes faites au Chatbot.~~ ✅ **FAIT**

*(Toutes les tâches de DEV 2A sont officiellement terminées ! 🎉)*

---

## 🔄 Fractionnement du travail entre DEV 2B et DEV 1C

Afin de mieux équilibrer la charge, les tâches initialement prévues pour le Backend de DEV 2B sont divisées avec DEV 1C.

### 🛠️ DEV 2B — Massogui Diop · Backend (Intégrations & Temps Réel)
> **Rôle :** Sécurité, intégrations externes et gestion du temps réel.

**Tâches :**
1. ~~**Intégration réelle des fournisseurs SMS** : Remplacer les logs mockés par de vraies API (Twilio, Orange, etc.) pour les SMS. (Les emails sont déjà gérés).~~ ✅ **FAIT**
2. ~~**WebSockets (Django Channels)** : Mise à jour en direct des Dashboards et de l'App Flutter sans polling.~~ ✅ **FAIT**
3. ~~**Tests Unitaires QA (Tâche 10)** : Validation des règles métiers d'Ibrahima et vérification de la génération sans erreur des PDF de Pape (Résidence, Décès, Mariage).~~ ✅ **FAIT**
4. ~~**Django Admin (Tâche 11)** : Mise à jour du Super Admin pour la gestion des 3 nouveaux dossiers avec affichage JSON avancé.~~ ✅ **FAIT**

*(Toutes les tâches de DEV 2B sont officiellement terminées ! 🎉)*

### 🔔 DEV 1C — Maïmouna Sall · Backend (Optimisations & Notifications)
> **Rôle :** En plus des notifications, du dashboard de stats et de l'export CSV, tu récupères une partie de l'optimisation.

**Tâches récupérées de DEV 2B :**
1. ~~**Mise en cache Redis (Throttling avancé)** : Configurer Redis pour soulager la base de données et rendre l'API ultra-rapide.~~ ✅ **FAIT**
2. **Configuration Sécurisée en Production** : Scripts Nginx/Gunicorn, et sécurisation des headers HTTP.
*(En plus des tâches d'origine : Notifications asynchrones, Export CSV, et Stats pour le Dashboard de DEV 2A).*
