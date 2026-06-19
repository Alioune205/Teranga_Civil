#!/bin/bash
# ============================================================
# TERANGA CIVIL — Corrections des 3 erreurs signalées
# Usage : bash fix_erreurs.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🔧 TERANGA CIVIL — Corrections erreurs"
echo ""

# ════════════════════════════════════════════════════════════
# FIX 1 — app_theme.dart
# CardTheme : `side` n'existe pas dans RoundedRectangleBorder à l'intérieur de CardTheme
# Fix : envelopper dans un Container ou utiliser surfaceTintColor + border via clipBehavior
# Solution propre : utiliser shape sans side (le border se gère au niveau du widget Card)
# ════════════════════════════════════════════════════════════

# FIX 2 — app_theme.dart
# DialogTheme : titleTextStyle et contentTextStyle ne sont plus des paramètres directs
# dans certaines versions de Flutter — utiliser ThemeData.textTheme à la place
# Fix : supprimer les deux lignes et gérer via les styles dans les widgets

# FIX 3 — remote_datasource.dart auth
# `res` est une variable locale au bloc `try` du login
# Elle n'est pas accessible dans le `catch`
# Fix : déclarer `res` avant le try, ou restructurer la logique

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

      // ── FIX 1 : CardTheme sans `side` dans RoundedRectangleBorder ──────────
      // Le border sur les cards se gère widget par widget via Container decoration
      // (voir recap_card.dart, _DossierCard, etc.) — pas au niveau du thème global
      cardTheme: const CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
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
            states.contains(WidgetState.selected)
                ? AppColors.secondary
                : AppColors.textHint),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.statusGreenLight
                : AppColors.divider),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.transparent),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
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

      // ── FIX 2 : DialogTheme sans titleTextStyle / contentTextStyle ──────────
      // Ces propriétés causent des warnings selon la version Flutter.
      // Les styles sont appliqués directement dans les widgets AlertDialog.
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall,
        iconColor: AppColors.textSecondary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
DART
echo "  ✅ FIX 1 & 2 — app_theme.dart corrigé"

# ════════════════════════════════════════════════════════════
# FIX 3 — auth remote_datasource.dart
# Problème : `res` déclaré dans le try n'est pas accessible dans le catch
# Solution : déclarer res avant le try, restructurer le login proprement
# ════════════════════════════════════════════════════════════

cat > lib/features/auth/data/remote_datasource.dart << 'DART'
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/auth_response_model.dart';

class AuthRemoteDatasource {
  final DioClient client;
  const AuthRemoteDatasource({required this.client});

  Future<LoginResponseModel> login({
    required String phone,
    required String pinHash,
  }) async {
    // FIX 3 : res déclaré en dehors du try pour être accessible partout
    Response? res;
    try {
      res = await client.post('/auth/login', data: {
        'phone': phone,
        'pin_hash': pinHash,
      });

      // 401 → identifiants incorrects
      if (res.statusCode == 401) {
        throw const InvalidCredentialsException();
      }

      if (res.statusCode == 200 && res.data != null) {
        return LoginResponseModel.fromJson(res.data as Map<String, dynamic>);
      }

      throw ApiException(
        message: 'Réponse invalide du serveur',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      // Si l'intercepteur a déjà converti en UnauthorizedException
      if (e.error is UnauthorizedException) {
        throw const InvalidCredentialsException();
      }
      // Ou si le status 401 remonte via DioException
      if (res?.statusCode == 401) {
        throw const InvalidCredentialsException();
      }
      rethrow;
    }
  }

  Future<void> register({
    required String phone,
    required String nom,
    required String registre,
    required String dateNaissance,
    required String communeId,
  }) async {
    final res = await client.post('/auth/register', data: {
      'phone': phone,
      'nom': nom,
      'registre': registre,
      'date_naissance': dateNaissance,
      'commune_id': communeId,
    });
    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = res.data;
      final msg = data is Map<String, dynamic>
          ? data['message'] as String? ?? 'Erreur inscription'
          : 'Erreur inscription';
      throw ApiException(message: msg, statusCode: res.statusCode);
    }
  }

  Future<String> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final res = await client.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
    });
    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      return data['token'] as String? ?? '';
    }
    throw const InvalidOtpException();
  }

  Future<void> resendOtp({required String phone}) async {
    await client.post('/auth/resend-otp', data: {'phone': phone});
  }

  Future<UserResponseModel> getMe() async {
    final res = await client.get('/auth/me');
    if (res.statusCode == 200 && res.data != null) {
      return UserResponseModel.fromJson(res.data as Map<String, dynamic>);
    }
    throw const UnauthorizedException();
  }
}
DART
echo "  ✅ FIX 3 — auth remote_datasource.dart corrigé"

echo ""
echo "✅ Les 3 erreurs sont corrigées :"
echo ""
echo "  FIX 1 — CardTheme : supprimé le BorderSide dans RoundedRectangleBorder"
echo "          (le border se gère widget par widget via Container decoration)"
echo ""
echo "  FIX 2 — DialogTheme : supprimé titleTextStyle et contentTextStyle"
echo "          (ces paramètres créent des warnings selon la version Flutter)"
echo ""
echo "  FIX 3 — AuthRemoteDatasource.login : Response? res déclarée avant le try"
echo "          pour être accessible dans le bloc catch"
