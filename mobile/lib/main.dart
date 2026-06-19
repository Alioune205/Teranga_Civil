import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Vérifier le token avant runApp — démarrage direct sans SplashScreen
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final initialRoute =
      (token != null && token.isNotEmpty) ? AppRoutes.home : AppRoutes.login;

  runApp(ProviderScope(
    child: TerangaCivilApp(initialRoute: initialRoute),
  ));
}

class TerangaCivilApp extends ConsumerWidget {
  final String initialRoute;
  const TerangaCivilApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider(initialRoute));
    return MaterialApp.router(
      title: 'TERANGA CIVIL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('wo', 'SN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
