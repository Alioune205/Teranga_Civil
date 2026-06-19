#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 2 : Core & Thème
# Usage : bash setup_etape2.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 2 : Core & Thème"
echo ""

# ── app_colors.dart ─────────────────────────────────────────
cat > lib/core/theme/app_colors.dart << 'DART'
import 'package:flutter/material.dart';

/// Palette de couleurs officielle TERANGA CIVIL.
/// À utiliser PARTOUT dans l'application — jamais de couleur codée en dur ailleurs.
abstract class AppColors {
  AppColors._();

  // ── Couleurs principales ─────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B2A6B); // Navy blue
  static const Color secondary = Color(0xFF4CAF82); // Mint green

  // ── Fond & surfaces ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Textes ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B2A6B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Statuts dossiers ─────────────────────────────────────────────────────
  static const Color statusAmber = Color(0xFFF59E0B); // En cours
  static const Color statusRed   = Color(0xFFEF4444); // Rejeté
  static const Color statusGreen = Color(0xFF4CAF82); // Prêt / Validé
  static const Color statusBlue  = Color(0xFF3B82F6); // En vérification

  // ── Backgrounds statuts (version claire) ─────────────────────────────────
  static const Color statusAmberLight = Color(0xFFFEF3C7);
  static const Color statusRedLight   = Color(0xFFFEE2E2);
  static const Color statusGreenLight = Color(0xFFD1FAE5);
  static const Color statusBlueLight  = Color(0xFFDBEAFE);

  // ── Bordures & séparateurs ───────────────────────────────────────────────
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF1B2A6B);
  static const Color divider     = Color(0xFFF3F4F6);

  // ── États boutons ────────────────────────────────────────────────────────
  static const Color buttonDisabledBg   = Color(0xFFD1D5DB);
  static const Color buttonDisabledText = Color(0xFF9CA3AF);

  // ── Erreur / validation inline ───────────────────────────────────────────
  static const Color error      = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // ── Succès ───────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF4CAF82);
  static const Color successLight = Color(0xFFD1FAE5);

  // ── Overlay & ombres ─────────────────────────────────────────────────────
  static const Color overlay = Color(0x801B2A6B);
  static const Color shadow  = Color(0x141B2A6B);

  // ── Transparent ──────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
}
DART
echo "  ✅ app_colors.dart"

# ── app_text_styles.dart ────────────────────────────────────
cat > lib/core/theme/app_text_styles.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles typographiques TERANGA CIVIL — Poppins uniquement.
abstract class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.2);

  static TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.25);

  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.3);

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.35);

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.4);

  static TextStyle get appBarTitle => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary, height: 1.4);

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.5);

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.5);

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5);

  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, height: 1.4);

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary, height: 1.4);

  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary, height: 1.4);

  static TextStyle get buttonPrimary => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary, height: 1.4, letterSpacing: 0.3);

  static TextStyle get buttonDisabled => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.buttonDisabledText, height: 1.4, letterSpacing: 0.3);

  static TextStyle get inputText => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.5);

  static TextStyle get inputLabel => GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary, height: 1.4);

  static TextStyle get inputHint => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textHint, height: 1.5);

  static TextStyle get inputError => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.error, height: 1.4);

  static TextStyle get link => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.secondary, height: 1.5,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.secondary);

  static TextStyle get linkPrimary => GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.primary, height: 1.5,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary);

  static TextStyle get badgeText => GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w600,
        height: 1.2, letterSpacing: 0.3);

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5);

  static TextStyle get tagline => GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.secondary, height: 1.5, letterSpacing: 0.5);

  static TextStyle get navLabel => GoogleFonts.poppins(
        fontSize: 10, fontWeight: FontWeight.w500, height: 1.2);

  static TextStyle get otpDigit => GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, height: 1.2);

  static TextStyle get amount => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: AppColors.primary, height: 1.2);

  static TextStyle get appNameBold => GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.primary, height: 1.2, letterSpacing: 2);

  static TextStyle get appNameRegular => GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w400,
        color: AppColors.primary, height: 1.2, letterSpacing: 2);

  static TextStyle withColor(TextStyle base, Color color) =>
      base.copyWith(color: color);
}
DART
echo "  ✅ app_text_styles.dart"

# ── app_theme.dart ──────────────────────────────────────────
cat > lib/core/theme/app_theme.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: Color(0xFFDDE3FF),
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.statusGreenLight,
        onSecondaryContainer: AppColors.secondary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.background,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        shadow: AppColors.shadow,
        scrim: AppColors.overlay,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.textOnPrimary, size: 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.navLabel.copyWith(color: AppColors.primary),
        unselectedLabelStyle: AppTextStyles.navLabel.copyWith(color: AppColors.textSecondary),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.buttonDisabledBg,
          disabledForegroundColor: AppColors.buttonDisabledText,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: AppTextStyles.buttonPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: AppTextStyles.link,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.buttonPrimary.copyWith(color: AppColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.inputHint,
        labelStyle: AppTextStyles.inputLabel,
        errorStyle: AppTextStyles.inputError,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.labelMedium,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.secondary : AppColors.textHint),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.statusGreenLight : AppColors.divider),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : AppColors.transparent),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        elevation: 8,
        modalElevation: 8,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall,
        iconColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
DART
echo "  ✅ app_theme.dart"

# ── app_constants.dart ──────────────────────────────────────
cat > lib/core/constants/app_constants.dart << 'DART'
abstract class AppConstants {
  AppConstants._();

  // ── Identité app ─────────────────────────────────────────────────────────
  static const String appName = 'TERANGA CIVIL';
  static const String appTagline = "L'administration proche de vous";
  static const String appVersion = '1.0.0';

  // ── API ───────────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.terangacivil.sn/v1';
  static const Duration apiConnectTimeout = Duration(seconds: 15);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);
  static const Duration apiSendTimeout = Duration(seconds: 30);

  // ── Clés stockage sécurisé ────────────────────────────────────────────────
  static const String keyAuthToken = 'auth_token';
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
DART
echo "  ✅ app_constants.dart"

# ── assets_constants.dart ───────────────────────────────────
cat > lib/core/constants/assets_constants.dart << 'DART'
abstract class Assets {
  Assets._();

  static const String logoTeranga    = 'assets/images/logo_teranga.svg';
  static const String lottieSuccess  = 'assets/lottie/success.json';
  static const String lottieLoading  = 'assets/lottie/loading.json';
  static const String senegalCommunes = 'assets/data/senegal_communes.json';
}
DART
echo "  ✅ assets_constants.dart"

# ── failures.dart ───────────────────────────────────────────
cat > lib/core/errors/failures.dart << 'DART'
abstract class Failure {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// ── Réseau & API ─────────────────────────────────────────────────────────────
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Pas de connexion internet. Vérifiez votre réseau.',
    super.code = 'NO_NETWORK',
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Le serveur est temporairement indisponible.',
    super.code = 'SERVER_ERROR',
  });
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure({required super.message, this.statusCode, super.code});
}

// ── Auth ──────────────────────────────────────────────────────────────────────
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Numéro de téléphone ou code PIN incorrect.',
    super.code = 'INVALID_CREDENTIALS',
  });
}

class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure({
    super.message = 'Code invalide ou expiré. Veuillez réessayer.',
    super.code = 'INVALID_OTP',
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expirée. Veuillez vous reconnecter.',
    super.code = 'UNAUTHORIZED',
  });
}

class PhoneAlreadyExistsFailure extends Failure {
  const PhoneAlreadyExistsFailure({
    super.message = 'Ce numéro est déjà associé à un compte.',
    super.code = 'PHONE_ALREADY_EXISTS',
  });
}

class TooManyAttemptsFailure extends Failure {
  const TooManyAttemptsFailure({
    super.message = 'Trop de tentatives. Réessayez dans quelques minutes.',
    super.code = 'TOO_MANY_ATTEMPTS',
  });
}

// ── Données locales ───────────────────────────────────────────────────────────
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erreur de stockage local.',
    super.code = 'CACHE_ERROR',
  });
}

class NotFoundLocalFailure extends Failure {
  const NotFoundLocalFailure({
    super.message = 'Données introuvables.',
    super.code = 'NOT_FOUND_LOCAL',
  });
}

// ── Validation ────────────────────────────────────────────────────────────────
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'VALIDATION_ERROR'});
}

// ── Dossiers ──────────────────────────────────────────────────────────────────
class DossierNotFoundFailure extends Failure {
  const DossierNotFoundFailure({
    super.message = 'Dossier introuvable.',
    super.code = 'DOSSIER_NOT_FOUND',
  });
}

class DownloadFailure extends Failure {
  const DownloadFailure({
    super.message = 'Impossible de télécharger le document.',
    super.code = 'DOWNLOAD_ERROR',
  });
}

// ── Paiement ─────────────────────────────────────────────────────────────────
class PaymentFailure extends Failure {
  const PaymentFailure({
    super.message = 'Le paiement a échoué. Vérifiez votre solde.',
    super.code = 'PAYMENT_FAILED',
  });
}

// ── Générique ─────────────────────────────────────────────────────────────────
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Une erreur inattendue est survenue.',
    super.code = 'UNEXPECTED_ERROR',
  });
}
DART
echo "  ✅ failures.dart"

# ── exceptions.dart ─────────────────────────────────────────
cat > lib/core/errors/exceptions.dart << 'DART'
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Pas de connexion internet.']);
  @override String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'La requête a expiré.']);
  @override String toString() => 'TimeoutException: $message';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  const ApiException({required this.message, this.statusCode, this.errorCode});
  @override String toString() => 'ApiException($statusCode, $errorCode): $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Non autorisé.']);
  @override String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  const ForbiddenException([this.message = 'Accès refusé.']);
  @override String toString() => 'ForbiddenException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Ressource introuvable.']);
  @override String toString() => 'NotFoundException: $message';
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Erreur serveur.']);
  @override String toString() => 'ServerException: $message';
}

class InvalidCredentialsException implements Exception {
  final String message;
  const InvalidCredentialsException([this.message = 'Identifiants incorrects.']);
  @override String toString() => 'InvalidCredentialsException: $message';
}

class InvalidOtpException implements Exception {
  final String message;
  const InvalidOtpException([this.message = 'Code OTP invalide.']);
  @override String toString() => 'InvalidOtpException: $message';
}

class PhoneAlreadyExistsException implements Exception {
  final String message;
  const PhoneAlreadyExistsException([this.message = 'Numéro déjà enregistré.']);
  @override String toString() => 'PhoneAlreadyExistsException: $message';
}

class TooManyAttemptsException implements Exception {
  final String message;
  const TooManyAttemptsException([this.message = 'Trop de tentatives.']);
  @override String toString() => 'TooManyAttemptsException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Erreur de cache local.']);
  @override String toString() => 'CacheException: $message';
}

class FileSizeExceededException implements Exception {
  final String message;
  const FileSizeExceededException([this.message = 'Fichier trop volumineux.']);
  @override String toString() => 'FileSizeExceededException: $message';
}

class PaymentException implements Exception {
  final String message;
  const PaymentException([this.message = 'Erreur de paiement.']);
  @override String toString() => 'PaymentException: $message';
}

class UnexpectedException implements Exception {
  final String message;
  const UnexpectedException([this.message = 'Erreur inattendue.']);
  @override String toString() => 'UnexpectedException: $message';
}
DART
echo "  ✅ exceptions.dart"

# ── validators.dart ─────────────────────────────────────────
cat > lib/core/utils/validators.dart << 'DART'
abstract class Validators {
  Validators._();

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de téléphone est requis.';
    final cleaned = value.trim().replaceAll(' ', '').replaceAll('-', '');
    final withoutCode = cleaned.replaceFirst('+221', '').replaceFirst('221', '');
    if (withoutCode.length != 9) return 'Entrez un numéro sénégalais valide (9 chiffres).';
    if (!RegExp(r'^[0-9]{9}$').hasMatch(withoutCode)) return 'Le numéro ne doit contenir que des chiffres.';
    if (!RegExp(r'^(7[0-8]|33)').hasMatch(withoutCode)) return 'Préfixe opérateur invalide (70-78 ou 33).';
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'Le code PIN est requis.';
    if (value.length != 6) return 'Le code PIN doit contenir exactement 6 chiffres.';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Le code PIN ne doit contenir que des chiffres.';
    if (_isTrivialPin(value)) return 'Choisissez un PIN plus sécurisé (évitez 123456, 000000…).';
    return null;
  }

  static String? pinConfirmation(String? value, String originalPin) {
    final pinError = pin(value);
    if (pinError != null) return pinError;
    if (value != originalPin) return 'Les deux codes PIN ne correspondent pas.';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'Le code est requis.';
    if (value.length != 6) return 'Le code doit contenir 6 chiffres.';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Le code ne doit contenir que des chiffres.';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le nom complet est requis.';
    final trimmed = value.trim();
    if (trimmed.length < 3) return 'Le nom doit contenir au moins 3 caractères.';
    if (trimmed.length > 100) return 'Le nom ne doit pas dépasser 100 caractères.';
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(trimmed)) return 'Le nom ne doit contenir que des lettres.';
    return null;
  }

  static String? registreNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de registre est requis.';
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length < 5 || trimmed.length > 20) return 'Le numéro doit contenir entre 5 et 20 caractères.';
    if (!RegExp(r'^[A-Z0-9\-\/]+$').hasMatch(trimmed)) return 'Format invalide (lettres, chiffres, - ou /).';
    return null;
  }

  static String? mariageRegistre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le numéro de registre du mariage est requis.';
    if (value.trim().length < 3) return 'Numéro de registre invalide.';
    return null;
  }

  static String? dateNaissance(DateTime? value) {
    if (value == null) return 'La date de naissance est requise.';
    if (value.isAfter(DateTime.now())) return 'La date ne peut pas être dans le futur.';
    if (DateTime.now().difference(value).inDays ~/ 365 > 120) return 'Date invalide.';
    return null;
  }

  static String? dateDeces(DateTime? value) {
    if (value == null) return 'La date de décès est requise.';
    if (value.isAfter(DateTime.now())) return 'La date ne peut pas être dans le futur.';
    return null;
  }

  static String? anneeMarriage(int? value) {
    if (value == null) return "L'année de mariage est requise.";
    final currentYear = DateTime.now().year;
    if (value < 1900 || value > currentYear) return "L'année doit être entre 1900 et $currentYear.";
    return null;
  }

  static String? region(String? value) => (value == null || value.isEmpty) ? 'Veuillez sélectionner une région.' : null;
  static String? departement(String? value) => (value == null || value.isEmpty) ? 'Veuillez sélectionner un département.' : null;
  static String? commune(String? value) => (value == null || value.isEmpty) ? 'Veuillez sélectionner une commune.' : null;

  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName est requis.';
    return null;
  }

  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final v in validators) { final e = v(value); if (e != null) return e; }
      return null;
    };
  }

  static bool _isTrivialPin(String pin) {
    const trivial = ['000000','111111','222222','333333','444444','555555','666666','777777','888888','999999','123456','654321'];
    if (trivial.contains(pin)) return true;
    bool asc = true, desc = true;
    for (int i = 0; i < pin.length - 1; i++) {
      final c = int.parse(pin[i]), n = int.parse(pin[i + 1]);
      if (n != c + 1) asc = false;
      if (n != c - 1) desc = false;
    }
    return asc || desc;
  }
}
DART
echo "  ✅ validators.dart"

# ── formatters.dart ─────────────────────────────────────────
cat > lib/core/utils/formatters.dart << 'DART'
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

abstract class AppFormatters {
  AppFormatters._();

  static String dateToFrench(DateTime date) => DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  static String dateShort(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  static String dateWithTime(DateTime date) => DateFormat("d MMM yyyy 'à' HH'h'mm", 'fr_FR').format(date);
  static String yearOnly(DateTime date) => DateFormat('yyyy').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'il y a ${diff.inDays ~/ 7} semaine(s)';
    if (diff.inDays < 365) return 'il y a ${diff.inDays ~/ 30} mois';
    return 'il y a ${diff.inDays ~/ 365} an(s)';
  }

  static String amountFCFA(int amount) {
    final f = NumberFormat('#,###', 'fr_FR').format(amount).replaceAll(',', '\u202f');
    return '$f FCFA';
  }

  static String phoneNumber(String phone) {
    String c = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (c.startsWith('221')) c = c.substring(3);
    if (c.length == 9) {
      return '+221 ${c.substring(0,2)} ${c.substring(2,5)} ${c.substring(5,7)} ${c.substring(7,9)}';
    }
    return phone;
  }

  static String maskPhone(String phone) {
    final parts = phoneNumber(phone).split(' ');
    if (parts.length < 5) return phone;
    return '${parts[0]} ${parts[1]} ${parts[2]} XXX XX ${parts[4]}';
  }

  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String titleCase(String text) => text.split(' ').map((w) =>
      w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');

  static String truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max - 3)}...';

  static String statusLabel(String status) {
    const labels = {
      'soumis': 'Soumis', 'en_verification': 'En vérification',
      'valide': 'Validé', 'pret': 'Prêt', 'rejete': 'Rejeté', 'en_cours': 'En cours',
    };
    return labels[status] ?? titleCase(status.replaceAll('_', ' '));
  }

  static String certTypeLabel(String type) {
    const labels = {
      'naissance': 'Certificat de naissance',
      'deces': 'Certificat de décès',
      'mariage': 'Certificat de mariage',
    };
    return labels[type] ?? titleCase(type);
  }

  static String paymentMethodLabel(String method) {
    const labels = {'wave': 'Wave', 'orange_money': 'Orange Money', 'free_money': 'Free Money'};
    return labels[method] ?? method;
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
  }
}

class UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
}
DART
echo "  ✅ formatters.dart"

echo ""
echo "✅ Étape 2 terminée — 9 fichiers créés"
echo ""
echo "Fichiers générés :"
echo "  lib/core/theme/app_colors.dart"
echo "  lib/core/theme/app_text_styles.dart"
echo "  lib/core/theme/app_theme.dart"
echo "  lib/core/constants/app_constants.dart"
echo "  lib/core/constants/assets_constants.dart"
echo "  lib/core/errors/failures.dart"
echo "  lib/core/errors/exceptions.dart"
echo "  lib/core/utils/validators.dart"
echo "  lib/core/utils/formatters.dart"
