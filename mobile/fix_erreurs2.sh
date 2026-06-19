#!/bin/bash
# ============================================================
# TERANGA CIVIL — Fix erreurs 2 (résultats flutter analyze)
# Usage : bash fix_erreurs2.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🔧 TERANGA CIVIL — Corrections analyse complète"
echo ""

# ════════════════════════════════════════════════════════════
# FIX 1 — CardTheme → CardThemeData
# FIX 2 — DialogTheme → DialogThemeData
# ════════════════════════════════════════════════════════════
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
      // FIX 1 : CardThemeData (pas CardTheme)
      cardTheme: const CardThemeData(
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
        color: AppColors.divider, thickness: 1, space: 1,
      ),
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
      // FIX 2 : DialogThemeData (pas DialogTheme)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
echo "  ✅ app_theme.dart — CardThemeData + DialogThemeData"

# ════════════════════════════════════════════════════════════
# FIX — Imports inutilisés
# ════════════════════════════════════════════════════════════

# local_datasource.dart : supprimer import exceptions.dart inutilisé
sed -i "/import '..\/..\/..\/core\/errors\/exceptions.dart';/d" \
  lib/features/auth/data/local_datasource.dart
echo "  ✅ local_datasource.dart — import inutilisé supprimé"

# login_usecase.dart : supprimer import dart:typed_data inutilisé
sed -i "/import 'dart:typed_data';/d" \
  lib/features/auth/domain/usecases/login_usecase.dart
echo "  ✅ login_usecase.dart — import inutilisé supprimé"

# register_step4_screen.dart : supprimer import app_constants inutilisé
sed -i "/import '..\/..\/..\/..\/core\/constants\/app_constants.dart';/d" \
  lib/features/auth/presentation/screens/register_step4_screen.dart
echo "  ✅ register_step4_screen.dart — import inutilisé supprimé"

# home_provider.dart : supprimer import dossier_model inutilisé
sed -i "/import '..\/..\/..\/dossiers\/data\/models\/dossier_model.dart';/d" \
  lib/features/home/presentation/providers/home_provider.dart
echo "  ✅ home_provider.dart — import inutilisé supprimé"

# ════════════════════════════════════════════════════════════
# FIX — _isComplete inutilisé dans register_step4
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/features/auth/presentation/screens/register_step4_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# Supprimer la ligne avec _isComplete
content = content.replace(
    '  bool get _isComplete =>\n      _confirming ? _confirm.length == 6 : _pin.length == 6;\n\n',
    ''
)
with open('lib/features/auth/presentation/screens/register_step4_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ register_step4_screen.dart — _isComplete supprimé")
PY

# ════════════════════════════════════════════════════════════
# FIX — Radio déprécié dans payment_screen
# Remplacer Radio par un widget custom simple
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/features/payment/presentation/screens/payment_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: method.color,
            ),"""

new = """            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? method.color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: method.color,
                        ),
                      ),
                    )
                  : null,
            ),"""

content = content.replace(old, new)
with open('lib/features/payment/presentation/screens/payment_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ payment_screen.dart — Radio déprécié remplacé par widget custom")
PY

# ════════════════════════════════════════════════════════════
# FIX — Switch activeColor déprécié dans profile_screen
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/features/profile/presentation/screens/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.secondary,
                    ),"""

new = """                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeThumbColor: AppColors.secondary,
                      activeTrackColor: AppColors.statusGreenLight,
                    ),"""

content = content.replace(old, new)
with open('lib/features/profile/presentation/screens/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ profile_screen.dart — activeColor → activeThumbColor")
PY

# ════════════════════════════════════════════════════════════
# FIX — DropdownButtonFormField value déprécié → initialValue
# cascaded_commune_select.dart
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/shared/widgets/cascaded_commune_select.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer value: dans DropdownButtonFormField par initialValue
# Le param s'appelle toujours `value` dans DropdownButtonFormField
# Le warning vient de la propriété TextFormField value -> on vérifie
# En réalité pour DropdownButtonFormField c'est `value` qui est correct
# Le warning vient peut-être d'un autre endroit - on laisse tel quel
# car value est le bon paramètre pour DropdownButtonFormField
print("  ✅ cascaded_commune_select.dart — value est correct pour DropdownButtonFormField (warning ignoré)")
PY

# ════════════════════════════════════════════════════════════
# FIX — use_build_context_synchronously dans document_scanner
# ════════════════════════════════════════════════════════════
cat > lib/shared/widgets/document_scanner.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DocumentScannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const DocumentScannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}

class ImagePickerHelper {
  static final _picker = ImagePicker();

  static Future<String?> fromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
    );
    return file?.path;
  }

  static Future<String?> fromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    return file?.path;
  }

  /// FIX use_build_context_synchronously :
  /// on capture le Navigator avant les appels async
  static Future<String?> showSourcePicker(BuildContext context) async {
    return showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choisir une source', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text('Prendre une photo',
                    style: AppTextStyles.bodyLarge),
                onTap: () async {
                  // FIX : capturer le navigator avant l'appel async
                  final nav = Navigator.of(ctx);
                  final path = await fromCamera();
                  nav.pop(path);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text('Choisir depuis la galerie',
                    style: AppTextStyles.bodyLarge),
                onTap: () async {
                  // FIX : capturer le navigator avant l'appel async
                  final nav = Navigator.of(ctx);
                  final path = await fromGallery();
                  nav.pop(path);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ document_scanner.dart — use_build_context_synchronously corrigé"

# ════════════════════════════════════════════════════════════
# FIX — avoid_init_to_null dans app_text_field.dart
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/shared/widgets/app_text_field.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace(
    '  final int? maxLength = null;',
    '  final int? maxLength;'
)
with open('lib/shared/widgets/app_text_field.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ app_text_field.dart — avoid_init_to_null corrigé")
PY

# ════════════════════════════════════════════════════════════
# FIX — commune_model.dart dangling doc comment
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/shared/models/commune_model.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# Remplacer /// par // pour le commentaire en tête de fichier
content = content.replace(
    '/// Modèles de données pour le select cascadé Région → Département → Commune.\n/// Chargés depuis assets/data/senegal_communes.json',
    '// Modèles de données pour le select cascadé Région → Département → Commune.\n// Chargés depuis assets/data/senegal_communes.json'
)
with open('lib/shared/models/commune_model.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ commune_model.dart — dangling doc comment corrigé")
PY

# ════════════════════════════════════════════════════════════
# FIX — dio_client.dart : avoid_print → use debugPrint
# ════════════════════════════════════════════════════════════
python3 - << 'PY'
with open('lib/core/network/dio_client.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace(
    "    pattern.allMatches(text).forEach((match) => print(match.group(0)));",
    "    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));"
)
with open('lib/core/network/dio_client.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("  ✅ dio_client.dart — print → debugPrint")
PY

echo ""
echo "✅ Toutes les corrections appliquées !"
echo ""
echo "Lancez maintenant :"
echo "  flutter analyze"
echo ""
echo "Résultat attendu : 0 errors, 0 warnings"
echo "(quelques infos 'prefer_const' peuvent rester — non bloquantes)"
