import 'package:flutter/foundation.dart' show kIsWeb;

abstract class AppConstants {
  AppConstants._();

  // ── Identité app ─────────────────────────────────────────────────────────
  static const String appName = 'TERANGA CIVIL';
  static const String appTagline = "L'administration proche de vous";
  static const String appVersion = '1.0.0';

  // ── API ───────────────────────────────────────────────────────────────────
  // Web (Chrome) : localhost. Mobile (émulateur ET vrai téléphone via USB) :
  // 127.0.0.1 — fonctionne grâce à `adb reverse tcp:8000 tcp:8000`, qui renvoie
  // le 127.0.0.1:8000 de l'appareil vers le backend du PC (pas besoin de WiFi
  // ni de l'IP LAN). Émulateur : `adb reverse` marche aussi (sinon 10.0.2.2).
  static final String apiBaseUrl =
      kIsWeb ? 'http://localhost:8000/api' : 'http://127.0.0.1:8000/api';

  // Hôte logique envoyé dans l'en-tête HTTP `Host`. La connexion TCP part bien
  // vers 10.0.2.2 (alias émulateur → PC hôte), mais Django valide le header
  // `Host` contre ALLOWED_HOSTS (= localhost,127.0.0.1). On force donc `localhost`
  // pour être accepté sans modifier le backend.
  static const String apiHostHeader = 'localhost';
  static const Duration apiConnectTimeout = Duration(seconds: 15);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);
  static const Duration apiSendTimeout = Duration(seconds: 30);

  // ── Clés stockage sécurisé ────────────────────────────────────────────────
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserPin = 'user_pin_hash';
  static const String keyUserId = 'user_id';
  static const String keyUserPhone = 'user_phone';
  static const String keyHasBeenLoggedOut = 'has_been_logged_out';

  // ── Clés shared_preferences ───────────────────────────────────────────────
  static const String prefSelectedLanguage = 'selected_language';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefUserProfile = 'user_profile_cache';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const int pinLength = 6;
  static const int otpLength = 6;
  static const int otpResendCooldownSeconds = 60;
  static const int maxLoginAttempts = 5;

  // ── Téléphone Sénégal ─────────────────────────────────────────────────────
  static const String senegalDialCode = '+221';
  static const int senegalPhoneLength = 9;

  // ── Inscription ───────────────────────────────────────────────────────────
  static const int registerTotalSteps = 4;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Paiement (FCFA) ──────────────────────────────────────────────────────
  static const int naissanceFeesFCFA = 500;
  static const int decesFeesFCFA = 500;
  static const int mariageFeesFCFA = 1000;
  static const int residenceFeesFCFA = 1000;
  // Demandes foncières (récépissé). Mutation : 1 000 F/m² — le montant exact
  // est confirmé par la mairie au traitement.
  static const int foncierFeesFCFA = 1000;

  // ── Délais estimés (jours ouvrés) ────────────────────────────────────────
  static const int naissanceDelayDays = 3;
  static const int decesDelayDays = 3;
  static const int mariageDelayDays = 5;

  // ── Langues ───────────────────────────────────────────────────────────────
  static const String langFrench = 'fr';
  static const String langWolof = 'wo';
  static const List<String> supportedLanguages = [langFrench, langWolof];

  // ── Animations ────────────────────────────────────────────────────────────
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration skeletonAnimDuration = Duration(milliseconds: 1200);

  // ── Types certificats ────────────────────────────────────────────────────
  static const String certTypeNaissance = 'naissance';
  static const String certTypeDeces = 'deces';
  static const String certTypeMariage = 'mariage';

  // ── Statuts dossiers ──────────────────────────────────────────────────────
  static const String statusSubmitted = 'soumis';
  static const String statusVerification = 'en_verification';
  static const String statusValidated = 'valide';
  static const String statusReady = 'pret';
  static const String statusRejected = 'rejete';
  static const String statusInProgress = 'en_cours';

  // ── Méthodes paiement ────────────────────────────────────────────────────
  static const String paymentWave = 'wave';
  static const String paymentOrangeMoney = 'orange_money';
  static const String paymentFreeMoney = 'free_money';
}
