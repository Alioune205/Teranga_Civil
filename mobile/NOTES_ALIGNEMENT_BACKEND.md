# Notes d'alignement Mobile ↔ Backend

> App mobile : `teranga_civil` (repo `Dioumadev221/front-mobile-terranga_civil`)
> Backend de référence : `Alioune205/Teranga-Civil` branche `DevAliouneSene` @ `38e90c9`
> Dernière synchro : 2026-06-12

---

## ✅ Déjà aligné côté mobile (rien à faire pour le backend)

| Fonction | Endpoint backend | État |
|---|---|---|
| Connexion | `POST /api/auth/login/` | OK |
| Inscription | `POST /api/auth/register/` (`first_name,last_name,password,password_confirm,phone?,email?`) | OK |
| OTP envoi | `POST /api/auth/otp/send/` (`identifier`) | OK *(corrigé)* |
| OTP vérif | `POST /api/auth/otp/verify/` (`identifier,code`) | OK *(corrigé)* |
| Refresh token | `POST /api/auth/refresh/` | OK |
| Profil | `GET /api/users/me/`, `PATCH /api/users/{id}/` | OK |
| Demandes | `GET/POST /api/dossiers/`, `GET /api/dossiers/{id}/`, `POST /api/dossiers/{id}/submit/` | OK |
| Téléchargement PDF | `GET /api/dossiers/{id}/download-pdf/` | OK *(corrigé)* |
| Paiement | `POST /api/initiate/` | OK |
| Notifications | `GET /api/notifications/`, `POST /api/notifications/mark-all-read/` | OK |
| Assistant IA | `POST /api/ai/ndiogoye/chat/` (`question,chat_history` → `answer`) | OK *(corrigé)* |

---

## 🔴 A — Demandes à l'équipe BACKEND (seul le backend peut le faire)

### A1. Endpoint de changement de mot de passe / PIN
Le mobile a un écran « changer le mot de passe / PIN » mais **aucun endpoint n'existe**.
- **Souhaité** : `POST /api/auth/change-password/` body `{ "old_password": "...", "new_password": "..." }`
- Réponse standard `{success, message}`. Auth requise (Bearer).

### A2. Enrichissement `metadata` du dossier depuis le Registre Civil
Le citoyen ne connaît **pas** les infos de son acte (parents, lieu, sexe, date…) — elles sont dans la base de la commune (`RegistreCivil`). Le mobile n'envoie que `numero_registre` + `annee_registre`.
- **Souhaité** : à la création d'un dossier (`POST /api/dossiers/`), le backend retrouve l'acte par `(numero_registre, annee_registre, commune)`, **vérifie qu'il correspond au nom du demandeur**, puis remplit `dossier.metadata` avec : `prenoms_enfant, nom_enfant, date_naissance_personne, lieu_naissance, sexe, prenom_pere, prenom_mere, nom_mere` (+ `registre_verifie`).
- Sans ça, le détail/PDF affichent ces champs vides.
- *(Une implémentation de référence existe sur la branche `backup/full-20260612` du repo principal, dans `apps/dossiers/views.py::create`.)*

---

## 🟠 B — À faire côté MOBILE (notre périmètre, à planifier)

### B1. OCR auto-remplissage (`extractOcr`)
Actuellement un **placeholder mock** (envoie un `image_path` string).
- À implémenter : `POST /api/ai/ocr/extract/` en **multipart** (`document` = fichier image, `dossier_type`), parser la réponse `{ extracted_text, extracted_data }`.
- Gérer l'image en **web** (bytes via `XFile.readAsBytes()`, pas un chemin de fichier).

### B2. Upload de documents (CNI) en web
`uploadDocument` utilise `MultipartFile.fromFile(path)` → **ne marche pas en web** (pas de chemin de fichier).
- À implémenter : `MultipartFile.fromBytes(...)` quand `kIsWeb`.

### B3. (Optionnel) Pré-vérification du registre
Le backend expose déjà `POST /api/dossiers/verify-registry/` (`numero_registre, annee_registre, commune, type_acte`).
- Le mobile pourrait l'appeler **avant** la soumission pour confirmer au citoyen que le registre correspond bien à son nom.

---

## 🔄 Rituel de synchronisation (à chaque push backend)
1. `git fetch` le repo backend (`DevAliouneSene`) — lecture seule.
2. Diff de l'API : `apps/*/urls.py`, `*/serializers.py`, `*/views.py`, `models.py`.
3. Adapter **uniquement** `teranga_civil/` (modèles `fromJson`, endpoints, payloads).
4. Vérifier en live + commit sur la branche mobile.
