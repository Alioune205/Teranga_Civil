#!/bin/bash
# ============================================================
# TERANGA CIVIL — Fix MaterialLocalizations not found
# Usage : bash fix_localizations.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🔧 Fix MaterialLocalizations..."
echo ""

# ── 1. Ajouter flutter_localizations dans pubspec.yaml ──────
python3 - << 'PY'
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# Ajouter flutter_localizations juste après "flutter:"
if 'flutter_localizations' not in content:
    content = content.replace(
        'dependencies:\n  flutter:\n    sdk: flutter',
        'dependencies:\n  flutter:\n    sdk: flutter\n  flutter_localizations:\n    sdk: flutter'
    )
    with open('pubspec.yaml', 'w', encoding='utf-8') as f:
        f.write(content)
    print("  ✅ pubspec.yaml — flutter_localizations ajouté")
else:
    print("  ✅ pubspec.yaml — flutter_localizations déjà présent")
PY

# ── 2. Réécrire main.dart avec les bons delegates ────────────
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les locales pour intl (dates en français)
  await initializeDateFormatting('fr_FR', null);

  // Portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente, icônes blanches
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: TerangaCivilApp(),
    ),
  );
}

class TerangaCivilApp extends ConsumerWidget {
  const TerangaCivilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TERANGA CIVIL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,

      // ── Delegates de localisation (obligatoires pour TextField, etc.) ──
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('wo', 'SN'),
        Locale('en', 'US'), // fallback
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
DART
echo "  ✅ main.dart — delegates GlobalMaterialLocalizations ajoutés"

echo ""
echo "Exécutez maintenant :"
echo "  flutter pub get"
echo "  flutter run"
