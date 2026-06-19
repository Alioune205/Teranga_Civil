#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 4 : Network & Router
# Usage : bash setup_etape4.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 4 : Network & Router"
echo ""

# ── dio_client.dart ─────────────────────────────────────────
cat > lib/core/network/dio_client.dart << 'DART'
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'network_interceptor.dart';

/// Provider du client Dio — injecté partout via Riverpod
final dioClientProvider = Provider<DioClient>((ref) {
  const storage = FlutterSecureStorage();
  return DioClient(storage: storage);
});

/// Client HTTP centralisé TERANGA CIVIL.
/// Configure : base URL, timeouts, headers JSON, intercepteurs JWT.
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage storage;

  DioClient({required this.storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiConnectTimeout,
        receiveTimeout: AppConstants.apiReceiveTimeout,
        sendTimeout: AppConstants.apiSendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Version': AppConstants.appVersion,
          'X-Platform': 'mobile',
        },
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      NetworkInterceptor(storage: storage, dio: _dio),
      // Log interceptor uniquement en debug
      // ignore: dead_code
      if (const bool.fromEnvironment('dart.vm.product') == false)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrintWrapped(obj.toString()),
        ),
    ]);
  }

  Dio get dio => _dio;

  // ── Méthodes HTTP raccourcies ─────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );

  /// Téléchargement de fichier (PDF dossier)
  Future<Response> download(
    String path,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) =>
      _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
      );
}

void debugPrintWrapped(String text) {
  final pattern = RegExp('.{1,800}');
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}
DART
echo "  ✅ dio_client.dart"

# ── network_interceptor.dart ────────────────────────────────
cat > lib/core/network/network_interceptor.dart << 'DART'
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Intercepteur réseau TERANGA CIVIL.
/// Responsabilités :
///   1. Injecter le JWT Bearer dans chaque requête
///   2. Détecter les 401 et nettoyer la session
///   3. Mapper les erreurs HTTP en exceptions typées
///   4. Détecter l'absence de réseau
class NetworkInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;

  NetworkInterceptor({required this.storage, required this.dio});

  // ── 1. Requête sortante — injecter le token ───────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await storage.read(key: AppConstants.keyAuthToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('[NetworkInterceptor] Erreur lecture token: $e');
    }
    handler.next(options);
  }

  // ── 2. Réponse reçue — mapper les erreurs HTTP ────────────
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode ?? 0;

    // 401 : session expirée → nettoyer et forcer reconnexion
    if (status == 401) {
      _clearSession();
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: const UnauthorizedException(),
        ),
        true,
      );
      return;
    }

    // 403 : accès refusé
    if (status == 403) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: const ForbiddenException(),
        ),
        true,
      );
      return;
    }

    // 404 : ressource introuvable
    if (status == 404) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: const NotFoundException(),
        ),
        true,
      );
      return;
    }

    // 4xx autres : erreur métier avec message du backend
    if (status >= 400 && status < 500) {
      final data = response.data;
      final message = _extractMessage(data) ?? 'Erreur de requête.';
      final code = _extractCode(data);
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: ApiException(
            message: message,
            statusCode: status,
            errorCode: code,
          ),
        ),
        true,
      );
      return;
    }

    handler.next(response);
  }

  // ── 3. Erreur réseau ─────────────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: err.type,
            error: const TimeoutException(),
          ),
        );
        return;

      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: err.type,
            error: const NetworkException(),
          ),
        );
        return;

      case DioExceptionType.badResponse:
        // Déjà traité dans onResponse si status < 500
        // Ici : 5xx serveur
        if (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              response: err.response,
              type: err.type,
              error: const ServerException(),
            ),
          );
          return;
        }
        handler.next(err);
        return;

      default:
        handler.next(err);
    }
  }

  // ── Utilitaires privés ────────────────────────────────────

  Future<void> _clearSession() async {
    try {
      await storage.delete(key: AppConstants.keyAuthToken);
      await storage.write(
        key: AppConstants.keyHasBeenLoggedOut,
        value: 'true',
      );
    } catch (e) {
      debugPrint('[NetworkInterceptor] Erreur nettoyage session: $e');
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String?;
    }
    return null;
  }

  String? _extractCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['code'] as String? ?? data['error_code'] as String?;
    }
    return null;
  }
}
DART
echo "  ✅ network_interceptor.dart"

# ── app_router.dart ─────────────────────────────────────────
cat > lib/core/router/app_router.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../shared/layout/main_scaffold.dart';

// ── Auth screens
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/register_step1_screen.dart';
import '../../features/auth/presentation/screens/register_step2_screen.dart';
import '../../features/auth/presentation/screens/register_step3_screen.dart';
import '../../features/auth/presentation/screens/register_step4_screen.dart';

// ── Home
import '../../features/home/presentation/screens/home_screen.dart';

// ── Certificates — Naissance
import '../../features/certificates/naissance/presentation/screens/beneficiary_choice_screen.dart';
import '../../features/certificates/naissance/presentation/screens/recap_self_screen.dart';
import '../../features/certificates/naissance/presentation/screens/other_person_screen.dart';
import '../../features/certificates/naissance/presentation/screens/recap_other_screen.dart';

// ── Certificates — Décès
import '../../features/certificates/deces/presentation/screens/deces_form_screen.dart';
import '../../features/certificates/deces/presentation/screens/deces_recap_screen.dart';

// ── Certificates — Mariage
import '../../features/certificates/mariage/presentation/screens/mariage_form_screen.dart';
import '../../features/certificates/mariage/presentation/screens/mariage_recap_screen.dart';

// ── Payment
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/payment/presentation/screens/payment_success_screen.dart';

// ── Dossiers
import '../../features/dossiers/presentation/screens/dossiers_list_screen.dart';
import '../../features/dossiers/presentation/screens/dossier_detail_screen.dart';

// ── Profile
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Noms de routes — utiliser ces constantes partout (jamais de chaînes en dur)
abstract class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const otpVerification = '/otp-verification';
  static const registerStep1 = '/register/step1';
  static const registerStep2 = '/register/step2';
  static const registerStep3 = '/register/step3';
  static const registerStep4 = '/register/step4';

  // Shell (bottom nav)
  static const home = '/home';
  static const dossiers = '/dossiers';
  static const profile = '/profile';

  // Naissance
  static const naissanceBeneficiary = '/certificates/naissance/beneficiary';
  static const naissanceRecapSelf = '/certificates/naissance/recap-self';
  static const naissanceOtherPerson = '/certificates/naissance/other-person';
  static const naissanceRecapOther = '/certificates/naissance/recap-other';

  // Décès
  static const decesForm = '/certificates/deces/form';
  static const decesRecap = '/certificates/deces/recap';

  // Mariage
  static const mariageForm = '/certificates/mariage/form';
  static const mariageRecap = '/certificates/mariage/recap';

  // Paiement
  static const payment = '/payment';
  static const paymentSuccess = '/payment/success';

  // Dossier détail
  static const dossierDetail = '/dossiers/:id';
  static String dossierDetailPath(String id) => '/dossiers/$id';
}

/// Provider du router — consommé dans MaterialApp.router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    routes: [
      // ── Splash ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const SplashScreen(),
        ),
      ),

      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          return _slidePage(
            state: state,
            child: OtpVerificationScreen(phone: phone),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.registerStep1,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RegisterStep1Screen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.registerStep2,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RegisterStep2Screen(registrationData: data),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.registerStep3,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RegisterStep3Screen(registrationData: data),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.registerStep4,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RegisterStep4Screen(registrationData: data),
          );
        },
      ),

      // ── Shell (Bottom Nav) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final index = _shellIndex(state.matchedLocation);
          return MainScaffold(currentIndex: index, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.dossiers,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const DossiersListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _slidePage(
                    state: state,
                    child: DossierDetailScreen(dossierId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _noTransitionPage(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Certificat de naissance ─────────────────────────────
      GoRoute(
        path: AppRoutes.naissanceBeneficiary,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const BeneficiaryChoiceScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.naissanceRecapSelf,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const RecapSelfScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.naissanceOtherPerson,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const OtherPersonScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.naissanceRecapOther,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: RecapOtherScreen(formData: data),
          );
        },
      ),

      // ── Certificat de décès ─────────────────────────────────
      GoRoute(
        path: AppRoutes.decesForm,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const DecesFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.decesRecap,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: DecesRecapScreen(formData: data),
          );
        },
      ),

      // ── Certificat de mariage ───────────────────────────────
      GoRoute(
        path: AppRoutes.mariageForm,
        pageBuilder: (context, state) => _slidePage(
          state: state,
          child: const MariageFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.mariageRecap,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: MariageRecapScreen(formData: data),
          );
        },
      ),

      // ── Paiement ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.payment,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _slidePage(
            state: state,
            child: PaymentScreen(paymentData: data),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        pageBuilder: (context, state) {
          final dossierId = state.extra as String? ?? '';
          return _slidePage(
            state: state,
            child: PaymentSuccessScreen(dossierId: dossierId),
          );
        },
      ),
    ],
  );
});

// ── Redirect global ────────────────────────────────────────────────────────────
Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  final isAuthenticated = token != null && token.isNotEmpty;

  final location = state.matchedLocation;

  // Pages accessibles sans auth
  const publicRoutes = [
    '/',
    '/login',
    '/otp-verification',
    '/register/step1',
    '/register/step2',
    '/register/step3',
    '/register/step4',
  ];

  final isPublic = publicRoutes.any((r) => location.startsWith(r));

  // Non authentifié sur une page privée → login
  if (!isAuthenticated && !isPublic) return AppRoutes.login;

  // Authentifié sur splash/login → home
  if (isAuthenticated && (location == '/' || location == '/login')) {
    return AppRoutes.home;
  }

  return null; // pas de redirect
}

// ── Index shell selon la route active ─────────────────────────────────────────
int _shellIndex(String location) {
  if (location.startsWith('/dossiers')) return 1;
  if (location.startsWith('/profile')) return 2;
  return 0; // /home par défaut
}

// ── Builders de pages ──────────────────────────────────────────────────────────

/// Page avec transition slide horizontal (standard TERANGA)
CustomTransitionPage<void> _slidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

/// Page sans transition (tabs bottom nav)
NoTransitionPage<void> _noTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

// ── Écran d'erreur ─────────────────────────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                'Page introuvable',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2A6B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Une erreur est survenue.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ app_router.dart"

# ── Mise à jour main.dart ────────────────────────────────────
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Localisation pour les date pickers
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('wo', 'SN'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
DART
echo "  ✅ main.dart mis à jour"

echo ""
echo "✅ Étape 4 terminée — 3 fichiers créés + main.dart mis à jour"
echo ""
echo "Fichiers générés :"
echo "  lib/core/network/dio_client.dart"
echo "  lib/core/network/network_interceptor.dart"
echo "  lib/core/router/app_router.dart"
echo "  lib/main.dart (mis à jour)"
echo ""
echo "⚠️  Note : l'app ne compile pas encore car les écrans"
echo "   des features (Étapes 5-8) sont vides."
echo "   C'est normal — on les remplira étape par étape."
