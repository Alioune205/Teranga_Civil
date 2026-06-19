# Documentation : Nouveau Flux OTP et Parcours d'Inscription

Ce document explique le fonctionnement du nouveau système de vérification OTP (One-Time Password) mis en place lors de l'inscription des citoyens sur la plateforme Teranga Civil, ainsi que les modifications techniques apportées.

## 1. Fonctionnement du Flux OTP

Le processus d'inscription a été sécurisé et se déroule désormais en deux étapes obligatoires pour garantir l'identité du citoyen.

### Étape 1 : Inscription Initiale
1. L'utilisateur remplit le formulaire d'inscription (nom, prénom, email/téléphone, mot de passe) et le soumet via l'application.
2. L'application appelle l'API `POST /api/auth/register/`.
3. Le compte utilisateur est créé en base de données avec le statut **inactif** (`is_verified = False`).
4. **Envoi du code** : Le système génère automatiquement un code OTP à 6 chiffres valable 10 minutes.
   - S'il s'agit d'un e-mail : un message contenant le code est envoyé via SendGrid.
   - S'il s'agit d'un numéro de téléphone : un SMS est envoyé via Twilio.
5. L'API retourne une réponse demandant la vérification, sans inclure les jetons de connexion :
   ```json
   {
     "data": {
       "needs_otp": true,
       "identifier": "citoyen@email.com"
     },
     "message": "Inscription réussie. Veuillez vérifier votre compte avec le code OTP."
   }
   ```

### Étape 2 : Vérification du Code
1. L'application redirige l'utilisateur vers un écran de vérification où il doit saisir les 6 chiffres reçus.
2. L'application appelle l'API `POST /api/auth/otp/verify/` en envoyant l'`identifier` et le `code`.
3. Le backend valide le code. S'il est valide et non expiré :
   - Le compte utilisateur passe à l'état **actif** (`is_verified = True`).
   - L'historique de connexion est mis à jour.
   - Le backend génère et retourne enfin les tokens JWT (`access` et `refresh`), connectant ainsi l'utilisateur.

*(Note : Si le code expire ou n'est pas reçu, l'utilisateur peut en demander un nouveau via la route `POST /api/auth/otp/send/`)*

---

## 2. Modifications Techniques Apportées

Pour implémenter ce comportement, plusieurs fichiers du backend ont été mis à jour sur la branche `DevAliouneSene` :

### Fichier : `backend/apps/authentication/views.py`
- **Refonte de `RegisterView`** : 
  - Suppression de la génération immédiate des tokens `RefreshToken.for_user(user)`.
  - Intégration de la logique de génération de l'`OTPCode`.
  - Intégration des appels aux services de communication (`SendGridEmailService` et `TwilioSMSService`) pour router l'OTP vers le bon canal (Email ou SMS).
  - Modification du format de la réponse (retourne désormais `needs_otp` et `identifier` au lieu des tokens).
- **Maintien de `VerifyOTPView`** : 
  - La logique de vérification existait déjà, mais elle agit maintenant comme point d'entrée final obligatoire du tunnel d'inscription.

### Fichier : `backend/apps/authentication/tests.py`
- **Ajout de Tests Unitaires** : 
  - Création de la classe de test `AuthenticationTests` pour automatiser la vérification de ces changements.
  - Ajout du test `test_register_creates_user_and_sends_otp` : Vérifie que le endpoint `/api/auth/register/` retourne bien un HTTP 201, ne retourne pas de tokens, indique `needs_otp: True`, et crée un compte inactif.
  - Ajout du test `test_verify_otp` : Simule l'envoi du bon code OTP et vérifie que le compte passe bien à `is_verified = True` tout en retournant les bons tokens d'accès.

### Modèles concernés (Rappel)
- Le modèle `User` (dans `apps/users/models.py`) utilise l'attribut `is_verified`.
- Le modèle `OTPCode` (dans `apps/users/models.py`) stocke de manière éphémère le code généré, sa date d'expiration et son état (utilisé ou non).
