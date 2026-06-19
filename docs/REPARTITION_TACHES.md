# 📋 TERANGA CIVIL — Répartition des Tâches (Sprint Post-Audit)

> [!NOTE]
> Ce document liste **uniquement les nouvelles tâches** à réaliser. Tout ce qui est déjà fonctionnel dans `Developpe` est exclu.
> Base URL API : `http://localhost:8000` (dev local) — Swagger : `/api/docs/`

---

## ✅ Ce qui est DÉJÀ livré (ne pas retoucher)

| Module | Statut |
|--------|--------|
| Auth JWT — login / register / refresh / logout | ✅ 100% |
| RBAC — 5 rôles (citizen, agent, officier, civil_admin, super_admin) | ✅ 100% |
| Modèle Dossier + Workflow complet (draft → completed) | ✅ 100% |
| Upload Documents sécurisé (SHA256 + magic bytes) | ✅ 100% |
| Audit Logs Middleware | ✅ 100% |
| Dashboard Stats API de base | ✅ 100% |
| Notifications FCM — modèle + envoi basique | ✅ 70% |
| OCR Tesseract cross-platform | ✅ 100% |
| FAQ Assistant Ndiogoye (regex basique) | ✅ basique |
| Vérification QR Code publique | ✅ basique |
| CRUD Communes | ✅ 100% |

---

## 🔧 DEV 1A — Lansana Coly · Backend Core + Co-IA

> [!IMPORTANT]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — DEV 1A débloque DEV 3, DEV 2B et DEV 4 sur le flux OTP.

### Tâches

#### 1. Système OTP — Vérification par téléphone ou email
```
Modèle : OTPCode { user, code (6 chiffres), expires_at, is_used }
POST /api/auth/otp/send/     → génère et envoie le code
POST /api/auth/otp/verify/   → valide le code et active le compte
```
- Expiration : 10 minutes
- Code à usage unique (`is_used = True` après validation)
- Envoi par email (via `django.core.mail`) ou SMS (via variable `.env`)

#### 2. Login par téléphone ou email
```
POST /api/auth/login/
Body : { "identifier": "77XXXXXXXX" ou "email@ex.com", "password": "..." }
```
- Adapter `CustomTokenObtainPairSerializer` pour accepter `phone` OU `email`
- Le champ s'appelle `identifier` côté frontend

#### 3. Throttling anti brute-force sur Login
```python
# Dans settings/base.py
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': ['rest_framework.throttling.AnonRateThrottle'],
    'DEFAULT_THROTTLE_RATES': {'anon': '5/min'},
}
```
- Limiter à **5 tentatives/minute** par IP sur `/api/auth/login/`

#### 4. Demande pour une autre personne (tierce personne)
```
Nouveaux champs sur Dossier :
  is_for_third_party  → BooleanField (default False)
  relationship        → CharField (ex: "père", "mère", "enfant")
  third_party_cni     → CharField (numéro CNI de la personne)

POST /api/dossiers/verify-register/
Body : { "commune_id": "...", "numero_registre": "...", "annee": 2023 }
Réponse : { "found": true, "nom_prenom": "Moussa Diallo", "message": "Le registre appartient à Moussa Diallo. Confirmez-vous ?" }
```

#### 5. Historique des connexions
```
Modèle : LoginHistory { user, ip_address, user_agent, timestamp, success }
Enregistrer dans le signal JWT post-login
GET /api/auth/login-history/  → liste des 20 dernières connexions
```

#### 6. Ndiogoye IA — Chatbot et Analyse IA
```
POST /api/ai/ndiogoye/chat/
Body    : { "message": "Je veux un extrait de naissance", "conversation_id": "uuid" }
Réponse : {
  "reply": "Bien sûr ! Quelle est votre commune ?",
  "action": "collect_info",
  "intent": "creer_dossier",
  "conversation_id": "uuid"
}
```
Intentions à gérer : `creer_dossier` · `suivre_dossier` · `info_procedure` · `salutation` · `inconnu`
**NB: Toute la partie IA vous est totalement déléguée.**

---

## 📄 DEV 1B — PATHÉ FALL · PDF Officiels + Timbres + Signatures

> [!CAUTION]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — Livraison critique pour le jury — tout le monde attend le PDF généré.

### Tâches

#### 1. Générateur de PDF officiel
```
Fichier à créer : apps/documents/pdf_generator.py
Classe : CivilActPDFGenerator

Structure du PDF :
  ┌─────────────────────────────────────┐
  │  [Armoiries SN]  RÉPUBLIQUE DU SÉNÉGAL │
  │  Commune de [X] — Centre d'état civil  │
  ├─────────────────────────────────────┤
  │         ACTE DE [TYPE]              │
  │    (données de l'acte)              │
  ├─────────────────────────────────────┤
  │  [QR Code]  [Timbre]  [Signature]   │
  │  Hash : XXXXXXXXXX  UUID : XXXX     │
  └─────────────────────────────────────┘

Méthodes :
  generate_birth_certificate(dossier)
  generate_marriage_certificate(dossier)
  generate_death_certificate(dossier)

Lib : reportlab (déjà dans requirements.txt ✅)
```

#### 2. Timbre numérique cryptographique
```
Modèle Timbre :
  numero_unique       → CharField (auto-généré, unique)
  montant             → PositiveIntegerField (200 / 300 / 500 FCFA)
  date_emission       → DateTimeField (auto_now_add)
  reference_paiement  → CharField
  document            → OneToOneField(Document)
  hash_timbre         → CharField (SHA256 de numero_unique+montant+document_uuid)

POST /api/documents/{id}/appliquer-timbre/   → réservé aux agents
```

#### 3. Signature officier
```
Modèle OfficierSignature :
  officier    → OneToOneField(User, role=civil_admin)
  cle_privee  → BinaryField (clé RSA chiffrée)
  cle_publique → TextField

POST /api/dossiers/{id}/signer/   → réservé aux officiers (role=civil_admin)
Effet : passe le dossier en status=completed + génère le PDF final
```

#### 4. QR Code amélioré
```
Avant : pointe vers dossier.reference
Après : pointe vers document UUID → /api/qr/verify/{document_uuid}/
Le QR code doit être généré avec qrcode (déjà installé ✅) et embarqué dans le PDF
```

---

## 🔔 DEV 1C — MAÏMOUNA SALL · Notifications + Dashboard + Export

> [!NOTE]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — Tout est débloqué immédiatement. Impact principal sur DEV 2A (dashboard admin).

### Tâches

#### 1. Notifications push asynchrones
```python
# Dans apps/notifications/signals.py
# Remplacer l'appel FCM synchrone par :
import threading

def send_notification_async(token, title, body):
    thread = threading.Thread(target=fcm_service.send, args=(token, title, body))
    thread.daemon = True
    thread.start()
```

#### 2. Historique notifications citoyen
```
GET  /api/notifications/           → liste paginée (is_read, title, body, created_at)
POST /api/notifications/{id}/mark-read/  → marque comme lue
```

#### 3. Dashboard enrichi
```
Ajouter à GET /api/dashboard/stats/ :
  dossiers_par_type     → { "birth_certificate": 120, "marriage": 45, ... }
  dossiers_par_commune  → top 5 { "commune": "Dakar", "count": 320 }
  agents_les_plus_actifs → top 3 { "agent": "...", "dossiers_traites": 80 }
  taux_approbation      → pourcentage dossiers approved/total
```

#### 4. Export CSV
```
GET /api/dashboard/export/?format=csv&date_debut=2024-01-01&date_fin=2024-12-31
Headers : Content-Type: text/csv, Content-Disposition: attachment; filename=export.csv
Colonnes : reference, type, statut, citoyen, commune, date_soumission, date_completion
Lib : csv.DictWriter natif Python (aucune dépendance externe)
```

---

## 🤖 DEV 1D — KALZ LE FRIMEUR · IA & OCR + Co-Ndiogoye

> [!NOTE]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — L’OCR est indépendant. Ndiogoye se développe **en binôme avec DEV 1A**.

### Tâches

#### 1. Extraction structurée depuis OCR
```python
# Améliorer apps/ai/ocr.py
def extract_cni_data(image_file) -> dict:
    """
    Retourne :
    {
      "nom": "DIALLO",
      "prenom": "Moussa",
      "numero_cni": "1 2345 67890 12345",
      "date_naissance": "15/03/1990",
      "lieu_naissance": "Dakar",
      "date_expiration": "15/03/2030"
    }
    """
```

#### 2. Pré-traitement image avant OCR
```python
# Avant d'envoyer à Tesseract :
from PIL import Image, ImageFilter, ImageEnhance

def preprocess_image(image):
    image = image.convert('L')           # Niveaux de gris
    image = image.filter(ImageFilter.SHARPEN)  # Netteté
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)        # Contraste x2
    return image
```

#### 3. Endpoint de confirmation OCR
```
POST /api/ai/ocr/extract/      → extrait les données (brutes)
POST /api/ai/ocr/confirm/      → l'utilisateur valide les données extraites
Body confirm : { "document_id": "uuid", "confirmed_data": { "nom": "...", ... } }
```

#### 4. Détection doublons par hash fichier
```python
# Dans apps/ai/validators.py
import hashlib

def compute_file_hash(file_obj) -> str:
    sha256 = hashlib.sha256()
    for chunk in file_obj.chunks():
        sha256.update(chunk)
    return sha256.hexdigest()

# Comparer avec Document.sha256_hash existant
```

#### 5. Exclusivité OCR
**NB: DEV 1D se concentre uniquement sur l'OCR. Toute la partie IA est gérée par DEV 1A.**

---

## 💻 DEV 2A — PAPE ALIOUNE SÈNE · Dashboards Administratifs Web React

> [!TIP]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — Vous êtes responsable **uniquement** des interfaces administratives Web. Vous ne devez pas développer l'application citoyen (celle-ci est exclusivement gérée sur mobile par DEV 3 & 4).

### Stack obligatoire : React + TailwindCSS + ShadCN

### Tâches

#### 1. Architecture et Routing Web (Super Admin & Officier d'État Civil)
```
/login                 → Connexion sécurisée des agents et officiers
/dashboard/super-admin → Vue globale (Gestion paiements, Audit Logs, Création Agents)
/dashboard/officier    → Vue Officier (Statistiques, Dossiers à valider, Approuver/Rejeter)
/dossiers              → Liste des dossiers avec filtres avancés
/citoyens              → Base de données des citoyens
```

#### 2. Modules de Sécurité et Paiement (Super Admin)
- Interface de gestion des paiements (que vous avez commencé).
- Visualisation des Audit Logs pour tracer toutes les actions des agents.

#### 3. Dashboard Officier d'État Civil et Datatables
- Table avec `TanStack Table` + filtres côté serveur.
- Actions : Assigner agent · Changer statut · Rejeter avec motif.
- **Bouton de validation finale** pour déclencher la génération du PDF sécurisé.

#### 4. Intégration Ndiogoye (Supervision)
- Interface pour visualiser l'historique des requêtes IA faites par les citoyens, afin d'optimiser le modèle.

---

## 🛠️ DEV 2B — MASSOGUI DIOP · Backend (Sécurité, Intégrations Externes & Temps réel)

> [!NOTE]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — Puisque l'application citoyenne mobile est gérée par Flutter (DEV 3 & 4) et le Web par DEV 2A, **vous êtes réaffecté à 100% sur le Backend** pour les fonctionnalités avancées.

### Nouvelles Tâches (Backend)

#### 1. Intégration réelle des fournisseurs SMS/Email
- Remplacer vos logs "Mock Fallback" par une véritable intégration d'API (ex: Twilio pour les SMS, SendGrid pour l'email) pour l'envoi effectif des OTP et des alertes.

#### 2. WebSockets (Temps réel) avec Django Channels
- Mettre en place un serveur WebSocket pour mettre à jour en direct le Dashboard de DEV 2A et l'App Flutter sans avoir besoin de rafraîchir la page (polling).

#### 3. Mise en cache Redis (Throttling avancé)
- Configurer Redis pour soulager la base de données et rendre le Throttle (Anti-Brute Force) de l'API ultra-rapide.

#### 4. Configuration Sécurisée en Production
- Script de configuration Nginx/Gunicorn.
- Sécurisation des headers HTTP.

---

## 📱 DEV 3 — DIOUMA DIONE · Flutter Auth + Onboarding

> [!TIP]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — Tout est débloqué sauf l’écran OTP (attend DEV 1A). Démarrer par onboarding + login.

### Stack : `flutter_bloc` ou `riverpod` · `dio` · `flutter_secure_storage`

### Tâches

#### 1. Architecture feature-first
```
lib/
  features/
    auth/          → login, register, otp, splash
    dossiers/      → (pour DEV 4)
    ndiogoye/      → (pour DEV 4)
  core/
    api/           → dio client + intercepteur JWT
    storage/       → flutter_secure_storage wrapper
```

#### 2. Onboarding (3 slides)
```
Slide 1 : Logo TERANGA CIVIL + "Vos démarches d'état civil, à portée de main"
Slide 2 : "Soumettez vos demandes en 3 étapes simples"
Slide 3 : "Suivez vos dossiers en temps réel"
→ Stocker onboarding_done dans SharedPreferences
```

#### 3. Auth Flow complet
```
SplashScreen
  └── token valide ?
        ├── OUI → HomeScreen
        └── NON → OnboardingScreen → LoginScreen

LoginScreen    → POST /api/auth/login/ (email OU téléphone)
RegisterScreen → POST /api/auth/register/
OTPScreen      → POST /api/auth/otp/verify/ (6 chiffres + minuterie 60s)
```

#### 4. Intercepteur Dio JWT
```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    final token = secureStorage.read('access_token');
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  },
  onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      // refresh → retry
    }
  },
));
```

---

## 📱 DEV 4 — FATOU MBAYE · Flutter Dossiers + Ndiogoye

> [!TIP]
> ⏰ **Deadline : 08 juin 2026 à 22h00** — Construire toute l’UI avec des **données mockées** sans attendre DEV 3. Brancher l’auth après.

### Tâches

#### 1. Liste des dossiers
```
GET /api/dossiers/
- Pull-to-refresh
- Tabs de filtre : Tous · En attente · En cours · Terminés
- DossierCard : référence + type + badge statut coloré + date
```

#### 2. Détail d'un dossier
```
GET /api/dossiers/{id}/
- Timeline de progression (Stepper Widget)
- Liste des documents (avec bouton télécharger)
- Section commentaires (GET/POST /api/dossiers/{id}/comments/)
- Bouton "Télécharger mon acte" → visible si status == 'completed'
```

#### 3. Nouvelle demande (StepperWidget)
```
Étape 1 : Choix du type (naissance / mariage / décès / déclaration)
Étape 2 : Formulaire selon le type (champs dynamiques)
Étape 3 : Upload des pièces (image_picker + file_picker)
          → POST /api/documents/upload/ pour chaque pièce
          → POST /api/dossiers/ pour soumettre
```

#### 4. Interface Chat Ndiogoye
```dart
// ChatScreen
ListView.builder(
  // bulles : message de l'utilisateur (droite) + réponse IA (gauche)
)
// Sur réception d'une action :
if (response.action == 'start_dossier') {
  Navigator.pushNamed(context, '/nouvelle-demande');
}
```

#### 5. Notifications push Firebase
```
1. Ajouter firebase_messaging dans pubspec.yaml
2. Enregistrer le token FCM :
   POST /api/notifications/register-device/
   Body : { "token": "FCM_TOKEN", "platform": "android" }
3. Gérer foreground (showDialog) et background (naviguer vers le dossier)
```

---

## 📊 Résumé rapide

| Dev | Nb tâches | Peut démarrer | Bloqué par |
|-----|-----------|---------------|------------|
| **DEV 1A** | 6 | ✅ 5 tâches | Rien |
| **DEV 1B** | 4 | ✅ 4 tâches | Rien |
| **DEV 1C** | 4 | ✅ 4 tâches | Rien |
| **DEV 1D** | 5 | ✅ 4 tâches | Ndiogoye → DEV 1A |
| **DEV 2A** | 5 | ✅ 3 tâches | DEV 1B (PDF) · DEV 1C (graphiques) |
| **DEV 2B** | 5 | ✅ 2 tâches | DEV 1A (OTP) · DEV 1B (PDF) · DEV 1D (OCR) |
| **DEV 3**  | 4 | ✅ 3 tâches | DEV 1A (OTP) |
| **DEV 4**  | 5 | ✅ 4 tâches | DEV 3 (auth) · DEV 1B (PDF) |

---

> [!CAUTION]
> ⏰ **Deadline globale : Dimanche 08 juin 2026 à 22h00** — Soutenance / Démo le lendemain. Zéro délai supplémentaire.

*Architecte Projet : DEV 1A — Lansana Coly · Mis à jour le 07 juin 2026*
