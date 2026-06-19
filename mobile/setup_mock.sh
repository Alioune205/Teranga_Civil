#!/bin/bash
# ============================================================
# TERANGA CIVIL — Mode Mock complet (test sans serveur)
# Usage : bash setup_mock.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Mode Mock"
echo ""

mkdir -p lib/core/mock

# ════════════════════════════════════════════════════════════
# 1. SERVICE MOCK CENTRAL
# ════════════════════════════════════════════════════════════
cat > lib/core/mock/mock_service.dart << 'DART'
/// Mode mock — simule toutes les réponses API en local.
/// Activé quand kMockMode = true dans mock_config.dart
///
/// Données de test disponibles :
///   Téléphone : 771234567
///   PIN       : 248631
///   OTP       : 123456
///   Dossiers  : 3 exemples (naissance, mariage, décès)

library mock_service;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mock_config.dart';

export 'mock_config.dart';

class MockService {
  MockService._();

  /// Simule un délai réseau réaliste
  static Future<void> delay([int ms = 800]) async {
    if (!kMockMode) return;
    await Future.delayed(Duration(milliseconds: ms));
  }

  // ── Auth ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String pinHash,
  }) async {
    await delay();
    debugPrint('[MOCK] login phone=$phone');

    // Accepter n'importe quel numéro + PIN non vide
    if (phone.isEmpty || pinHash.isEmpty) {
      throw Exception('Identifiants incorrects');
    }

    // Si l'utilisateur s'est déjà déconnecté → needs_otp = true
    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'mock_user_001',
      'needs_otp': false, // pas d'OTP en mock
    };
  }

  static Future<Map<String, dynamic>> register({
    required String phone,
    required String nom,
    required String registre,
    required String dateNaissance,
    required String communeId,
  }) async {
    await delay();
    debugPrint('[MOCK] register phone=$phone nom=$nom');
    return {'success': true, 'otp_sent': true};
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await delay(600);
    debugPrint('[MOCK] verifyOtp code=$code');

    // Accepter n'importe quel code à 6 chiffres
    if (code.length != 6) {
      throw Exception('Code OTP invalide');
    }

    return {
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  static Future<Map<String, dynamic>> resendOtp({
    required String phone,
  }) async {
    await delay(500);
    debugPrint('[MOCK] resendOtp phone=$phone');
    return {'success': true};
  }

  static Future<Map<String, dynamic>> getMe() async {
    await delay(400);
    return {
      'id': 'mock_user_001',
      'phone': '771234567',
      'nom': 'Amadou Diallo',
      'registre': 'SN-123456-A',
      'date_naissance': '1990-05-15',
      'commune_id': 'DK-DK-01',
      'commune_nom': 'Dakar Plateau',
    };
  }

  // ── Certificats ─────────────────────────────────────────

  static Future<Map<String, dynamic>> submitCertificate(
      Map<String, dynamic> payload) async {
    await delay(1000);
    final type = payload['type'] as String? ?? 'naissance';
    debugPrint('[MOCK] submitCertificate type=$type');
    final id = 'DOS-${type.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    return {'dossier_id': id, 'status': 'soumis'};
  }

  // ── Dossiers ────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDossiers() async {
    await delay(600);
    return [
      {
        'id': 'DOS-NAISSANCE-001',
        'type': 'naissance',
        'status': 'en_verification',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'commune_nom': 'Dakar Plateau',
        'beneficiary_nom': 'Amadou Diallo',
        'frais': 500,
      },
      {
        'id': 'DOS-MARIAGE-002',
        'type': 'mariage',
        'status': 'pret',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 7))
            .toIso8601String(),
        'commune_nom': 'Médina',
        'beneficiary_nom': 'Oumar Diop & Aïssatou Fall',
        'frais': 1000,
      },
      {
        'id': 'DOS-DECES-003',
        'type': 'deces',
        'status': 'soumis',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'commune_nom': 'Pikine Est',
        'beneficiary_nom': 'Mamadou Ba',
        'frais': 500,
      },
    ];
  }

  static Future<Map<String, dynamic>> getDossierById(String id) async {
    await delay(400);
    final all = await getDossiers();
    return all.firstWhere(
      (d) => d['id'] == id,
      orElse: () => all.first,
    );
  }

  // ── Paiement ────────────────────────────────────────────

  static Future<Map<String, dynamic>> initiatePayment({
    required String dossierId,
    required String method,
    required String phone,
  }) async {
    await delay(1200);
    debugPrint('[MOCK] payment dossier=$dossierId method=$method');
    return {
      'success': true,
      'receipt': 'REC-${DateTime.now().millisecondsSinceEpoch}',
      'transaction_id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // ── Profil ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    await delay(600);
    debugPrint('[MOCK] updateProfile $data');
    final base = await getMe();
    return {...base, ...data};
  }

  static Future<void> changePin({
    required String oldPinHash,
    required String newPin,
  }) async {
    await delay(600);
    debugPrint('[MOCK] changePin ok');
  }

  // ── Assistant ────────────────────────────────────────────

  static Future<Map<String, dynamic>> sendAssistantMessage({
    required String message,
    required String language,
  }) async {
    await delay(1000);
    debugPrint('[MOCK] assistant message=$message lang=$language');

    final responses = language == 'fr'
        ? _frResponses
        : _woResponses;

    // Réponse contextuelle simple
    final msg = message.toLowerCase();
    if (msg.contains('naissance')) {
      return {'response': responses['naissance']!};
    } else if (msg.contains('mariage')) {
      return {'response': responses['mariage']!};
    } else if (msg.contains('décès') || msg.contains('deces')) {
      return {'response': responses['deces']!};
    } else if (msg.contains('dossier') || msg.contains('suiv')) {
      return {'response': responses['dossier']!};
    } else if (msg.contains('frais') || msg.contains('prix') || msg.contains('coût')) {
      return {'response': responses['frais']!};
    }
    return {'response': responses['default']!};
  }

  static const _frResponses = {
    'naissance': 'Pour demander un certificat de naissance, '
        'allez dans "Certificat de naissance" depuis l\'accueil, '
        'choisissez si c\'est pour vous ou une autre personne, '
        'vérifiez les informations et payez les frais de 500 FCFA. '
        'Le délai de traitement est de 3 jours ouvrés.',
    'mariage': 'Pour un certificat de mariage, sélectionnez '
        '"Certificat de mariage" depuis l\'accueil, renseignez '
        'la commune, le numéro de registre, l\'année et les noms '
        'des époux. Les frais sont de 1 000 FCFA, délai 5 jours ouvrés.',
    'deces': 'Pour un certificat de décès, sélectionnez '
        '"Certificat de décès" depuis l\'accueil, renseignez '
        'la commune, le nom du défunt, le numéro de registre '
        'et la date de décès. Les frais sont de 500 FCFA.',
    'dossier': 'Pour suivre votre dossier, cliquez sur l\'onglet '
        '"Dossiers" dans la barre de navigation en bas. '
        'Vous verrez le statut de chaque demande : '
        'Soumis → En vérification → Validé → Prêt.',
    'frais': 'Les frais de service sont :\n'
        '• Certificat de naissance : 500 FCFA\n'
        '• Certificat de décès : 500 FCFA\n'
        '• Certificat de mariage : 1 000 FCFA\n'
        'Paiement accepté : Wave, Orange Money, Free Money.',
    'default': 'Bonjour ! Je suis l\'assistant TERANGA CIVIL. '
        'Je peux vous aider avec vos demandes de certificats '
        'd\'état civil (naissance, mariage, décès), le suivi '
        'de vos dossiers et les informations sur les frais et délais. '
        'Que puis-je faire pour vous ?',
  };

  static const _woResponses = {
    'naissance': 'Ngir dëkk certificat bu naissance, dem ci "Certificat de naissance" '
        'ci kanam. Tann boo bëggee ak yow walla nit ku bari. '
        'Jëfandiku ko ak 500 FCFA. Délai bi dafa 3 fan.',
    'mariage': 'Certificat bu mariage bi, tëral "Certificat de mariage". '
        'Bind commune bi, numéro bu registre, at ak tur yu jëkkër ak jabar. '
        'Jëfandiku ko ak 1 000 FCFA, délai 5 fan.',
    'deces': 'Certificat bu décès, tëral "Certificat de décès". '
        'Bind commune, tur bu nit bu def, numéro bu registre ak bés bu maat bi. '
        'Jëfandiku ko ak 500 FCFA.',
    'dossier': 'Ngir xool sa dossier, jël onglet "Dossiers" ci kanam. '
        'Dina def statut bu sa demande : Soumis → Vérification → Validé → Prêt.',
    'frais': 'Jëfandiku yi :\n'
        '• Naissance : 500 FCFA\n'
        '• Décès : 500 FCFA\n'
        '• Mariage : 1 000 FCFA\n'
        'Paiement : Wave, Orange Money, Free Money.',
    'default': 'Mangi fi ! Maa ngi Assistant TERANGA CIVIL. '
        'Maa ngi dem ci kanam ak certificats yu état civil, '
        'suivi yu dossiers ak yënu jëfandiku. '
        'Lan laa mëna def ngir yëngël ci kanam ?',
  };
}
DART
echo "  ✅ mock_service.dart"

# ════════════════════════════════════════════════════════════
# 2. CONFIG MOCK (activer/désactiver)
# ════════════════════════════════════════════════════════════
cat > lib/core/mock/mock_config.dart << 'DART'
/// Mettre kMockMode = false pour connecter le vrai backend
const bool kMockMode = true;
DART
echo "  ✅ mock_config.dart"

# ════════════════════════════════════════════════════════════
# 3. DIO CLIENT — injecter le mock
# ════════════════════════════════════════════════════════════
cat > lib/core/network/dio_client.dart << 'DART'
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../mock/mock_config.dart';
import 'network_interceptor.dart';
import 'mock_interceptor.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  const storage = FlutterSecureStorage();
  return DioClient(storage: storage);
});

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

    if (kMockMode) {
      // En mode mock : intercepteur qui retourne des données locales
      _dio.interceptors.add(MockInterceptor());
      debugPrint('[MOCK] Mode mock activé — aucun serveur requis');
    } else {
      // En mode production : vrai intercepteur JWT
      _dio.interceptors.add(NetworkInterceptor(storage: storage, dio: _dio));
    }
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.get<T>(path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.post<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> put<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.put<T>(path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

  Future<Response<T>> delete<T>(String path,
      {dynamic data,
      Options? options,
      CancelToken? cancelToken}) =>
      _dio.delete<T>(path,
          data: data,
          options: options,
          cancelToken: cancelToken);

  Future<Response> download(String path, String savePath,
      {ProgressCallback? onReceiveProgress, CancelToken? cancelToken}) =>
      _dio.download(path, savePath,
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.bytes));
}
DART
echo "  ✅ dio_client.dart mis à jour"

# ════════════════════════════════════════════════════════════
# 4. MOCK INTERCEPTOR — intercepte tous les appels Dio
# ════════════════════════════════════════════════════════════
cat > lib/core/network/mock_interceptor.dart << 'DART'
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../mock/mock_service.dart';

/// Intercepte tous les appels HTTP et retourne des données mock.
/// Aucune requête réseau n'est effectuée en mode mock.
class MockInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final method = options.method.toUpperCase();
    final data = options.data as Map<String, dynamic>? ?? {};

    debugPrint('[MOCK] $method $path');

    try {
      final responseData = await _handleRequest(method, path, data);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: responseData,
        ),
      );
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: e.toString(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': e.toString()},
          ),
        ),
      );
    }
  }

  Future<dynamic> _handleRequest(
    String method,
    String path,
    Map<String, dynamic> data,
  ) async {
    // ── Auth ──────────────────────────────────────────────
    if (path == '/auth/login') {
      return MockService.login(
        phone: data['phone'] as String? ?? '',
        pinHash: data['pin_hash'] as String? ?? '',
      );
    }
    if (path == '/auth/register') {
      return MockService.register(
        phone: data['phone'] as String? ?? '',
        nom: data['nom'] as String? ?? '',
        registre: data['registre'] as String? ?? '',
        dateNaissance: data['date_naissance'] as String? ?? '',
        communeId: data['commune_id'] as String? ?? '',
      );
    }
    if (path == '/auth/verify-otp') {
      return MockService.verifyOtp(
        phone: data['phone'] as String? ?? '',
        code: data['code'] as String? ?? '',
      );
    }
    if (path == '/auth/resend-otp') {
      return MockService.resendOtp(
        phone: data['phone'] as String? ?? '',
      );
    }
    if (path == '/auth/me') {
      return MockService.getMe();
    }

    // ── Certificats ───────────────────────────────────────
    if (path == '/certificates/submit') {
      return MockService.submitCertificate(data);
    }

    // ── Dossiers ──────────────────────────────────────────
    if (path == '/dossiers' && method == 'GET') {
      return MockService.getDossiers();
    }
    if (path.startsWith('/dossiers/') && method == 'GET') {
      final id = path.replaceFirst('/dossiers/', '');
      return MockService.getDossierById(id);
    }

    // ── Paiement ──────────────────────────────────────────
    if (path == '/payment/initiate') {
      return MockService.initiatePayment(
        dossierId: data['dossier_id'] as String? ?? '',
        method: data['method'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
      );
    }

    // ── Profil ────────────────────────────────────────────
    if (path == '/profile/update') {
      return MockService.updateProfile(data);
    }
    if (path == '/profile/change-pin') {
      await MockService.changePin(
        oldPinHash: data['old_pin_hash'] as String? ?? '',
        newPin: data['new_pin'] as String? ?? '',
      );
      return {'success': true};
    }

    // ── Assistant ─────────────────────────────────────────
    if (path == '/assistant/chat') {
      return MockService.sendAssistantMessage(
        message: data['message'] as String? ?? '',
        language: data['language'] as String? ?? 'fr',
      );
    }

    // Route inconnue
    debugPrint('[MOCK] Route non gérée: $method $path');
    return {'success': true, 'message': 'mock ok'};
  }
}
DART
echo "  ✅ mock_interceptor.dart"

# ════════════════════════════════════════════════════════════
# 5. BANNER MOCK dans main.dart
# ════════════════════════════════════════════════════════════
cat > lib/main.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/mock/mock_config.dart';

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

  runApp(const ProviderScope(child: TerangaCivilApp()));
}

class TerangaCivilApp extends ConsumerWidget {
  const TerangaCivilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TERANGA CIVIL',
      // Bannière orange "MOCK" visible en mode test
      debugShowCheckedModeBanner: kMockMode,
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
      // Bannière MOCK visible en haut de l'écran
      builder: kMockMode
          ? (context, child) => Stack(
                children: [
                  child!,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.orange.withValues(alpha: 0.85),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: const Text(
                          '⚠️ MODE TEST — Données simulées',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
          : null,
    );
  }
}
DART
echo "  ✅ main.dart — bannière MODE TEST ajoutée"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Mode mock installé !"
echo ""
echo "Données de test :"
echo "  📱 Téléphone : n'importe quel numéro valide"
echo "  🔑 PIN       : n'importe quel code à 6 chiffres"
echo "  📨 OTP       : n'importe quel code à 6 chiffres"
echo ""
echo "Pour désactiver le mock (vrai backend) :"
echo "  → lib/core/mock/mock_config.dart"
echo "  → Mettre kMockMode = false"
echo ""
echo "Lancer l'app :"
echo "  flutter run"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
