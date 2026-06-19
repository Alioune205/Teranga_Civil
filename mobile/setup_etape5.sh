#!/bin/bash
# ============================================================
# TERANGA CIVIL — Étape 5 : Feature AUTH (S01 à S06)
# Usage : bash setup_etape5.sh (depuis la racine du projet)
# ============================================================
set -e
echo "🚀 TERANGA CIVIL — Installation Étape 5 : Feature AUTH"
echo ""

# ════════════════════════════════════════════════════════════
# DOMAIN
# ════════════════════════════════════════════════════════════

cat > lib/features/auth/domain/models/user_model.dart << 'DART'
/// Modèle utilisateur domaine — indépendant de l'API
class UserModel {
  final String id;
  final String phone;
  final String nom;
  final String registre;
  final DateTime dateNaissance;
  final String communeId;
  final String communeNom;
  final String? regionId;
  final String? departementId;

  const UserModel({
    required this.id,
    required this.phone,
    required this.nom,
    required this.registre,
    required this.dateNaissance,
    required this.communeId,
    required this.communeNom,
    this.regionId,
    this.departementId,
  });

  UserModel copyWith({
    String? id, String? phone, String? nom, String? registre,
    DateTime? dateNaissance, String? communeId, String? communeNom,
    String? regionId, String? departementId,
  }) => UserModel(
    id: id ?? this.id,
    phone: phone ?? this.phone,
    nom: nom ?? this.nom,
    registre: registre ?? this.registre,
    dateNaissance: dateNaissance ?? this.dateNaissance,
    communeId: communeId ?? this.communeId,
    communeNom: communeNom ?? this.communeNom,
    regionId: regionId ?? this.regionId,
    departementId: departementId ?? this.departementId,
  );
}
DART
echo "  ✅ user_model.dart"

cat > lib/features/auth/domain/repository.dart << 'DART'
import 'models/user_model.dart';

/// Contrat abstrait — la couche data l'implémente, la présentation ne la connaît pas
abstract class AuthRepository {
  Future<({String token, String userId, bool needsOtp})> login({
    required String phone,
    required String pinHash,
  });

  Future<void> register({
    required String phone,
    required String nom,
    required String registre,
    required DateTime dateNaissance,
    required String communeId,
  });

  Future<String> verifyOtp({required String phone, required String code});

  Future<void> resendOtp({required String phone});

  Future<UserModel> getMe();

  Future<void> saveToken(String token);
  Future<void> saveUserId(String userId);
  Future<void> savePhone(String phone);
  Future<void> savePin(String pinHash);
  Future<void> setLoggedOut(bool value);

  Future<String?> getToken();
  Future<String?> getSavedPhone();
  Future<bool> hasBeenLoggedOut();

  Future<void> logout();
}
DART
echo "  ✅ auth repository.dart"

cat > lib/features/auth/domain/usecases/login_usecase.dart << 'DART'
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../repository.dart';

class LoginUsecase {
  final AuthRepository repository;
  const LoginUsecase(this.repository);

  Future<({String token, String userId, bool needsOtp})> call({
    required String phone,
    required String pin,
  }) async {
    final pinHash = _hashPin(pin);
    final result = await repository.login(phone: phone, pinHash: pinHash);
    await repository.saveToken(result.token);
    await repository.saveUserId(result.userId);
    await repository.savePhone(phone);
    return result;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
DART
echo "  ✅ login_usecase.dart"

cat > lib/features/auth/domain/usecases/register_usecase.dart << 'DART'
import '../repository.dart';

class RegisterUsecase {
  final AuthRepository repository;
  const RegisterUsecase(this.repository);

  Future<void> call({
    required String phone,
    required String nom,
    required String registre,
    required DateTime dateNaissance,
    required String communeId,
  }) => repository.register(
        phone: phone,
        nom: nom,
        registre: registre,
        dateNaissance: dateNaissance,
        communeId: communeId,
      );
}
DART
echo "  ✅ register_usecase.dart"

cat > lib/features/auth/domain/usecases/verify_otp_usecase.dart << 'DART'
import '../repository.dart';

class VerifyOtpUsecase {
  final AuthRepository repository;
  const VerifyOtpUsecase(this.repository);

  Future<void> call({required String phone, required String code}) async {
    final token = await repository.verifyOtp(phone: phone, code: code);
    await repository.saveToken(token);
  }
}
DART
echo "  ✅ verify_otp_usecase.dart"

cat > lib/features/auth/domain/usecases/resend_otp_usecase.dart << 'DART'
import '../repository.dart';

class ResendOtpUsecase {
  final AuthRepository repository;
  const ResendOtpUsecase(this.repository);

  Future<void> call({required String phone}) => repository.resendOtp(phone: phone);
}
DART
echo "  ✅ resend_otp_usecase.dart"

# ════════════════════════════════════════════════════════════
# DATA
# ════════════════════════════════════════════════════════════

cat > lib/features/auth/data/models/auth_response_model.dart << 'DART'
import '../../domain/models/user_model.dart';

class LoginResponseModel {
  final String token;
  final String userId;
  final bool needsOtp;

  const LoginResponseModel({
    required this.token,
    required this.userId,
    required this.needsOtp,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        token: json['token'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        needsOtp: json['needs_otp'] as bool? ?? false,
      );
}

class UserResponseModel {
  final String id;
  final String phone;
  final String nom;
  final String registre;
  final String dateNaissance;
  final String communeId;
  final String communeNom;

  const UserResponseModel({
    required this.id,
    required this.phone,
    required this.nom,
    required this.registre,
    required this.dateNaissance,
    required this.communeId,
    required this.communeNom,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) =>
      UserResponseModel(
        id: json['id'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        registre: json['registre'] as String? ?? '',
        dateNaissance: json['date_naissance'] as String? ?? '',
        communeId: json['commune_id'] as String? ?? '',
        communeNom: json['commune_nom'] as String? ?? '',
      );

  UserModel toDomain() => UserModel(
        id: id,
        phone: phone,
        nom: nom,
        registre: registre,
        dateNaissance: DateTime.tryParse(dateNaissance) ?? DateTime(1990),
        communeId: communeId,
        communeNom: communeNom,
      );
}
DART
echo "  ✅ auth_response_model.dart"

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
    try {
      final res = await client.post('/auth/login', data: {
        'phone': phone,
        'pin_hash': pinHash,
      });
      if (res.statusCode == 200 && res.data != null) {
        return LoginResponseModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw ApiException(message: 'Réponse invalide', statusCode: res.statusCode);
    } on DioException catch (e) {
      if (e.error is UnauthorizedException || res?.statusCode == 401) {
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
      final msg = (res.data as Map<String, dynamic>?)?['message'] ?? 'Erreur inscription';
      throw ApiException(message: msg as String, statusCode: res.statusCode);
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
      return (res.data as Map<String, dynamic>)['token'] as String;
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
echo "  ✅ remote_datasource.dart"

cat > lib/features/auth/data/local_datasource.dart << 'DART'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

class AuthLocalDatasource {
  final FlutterSecureStorage secureStorage;

  const AuthLocalDatasource({required this.secureStorage});

  Future<void> saveToken(String token) =>
      secureStorage.write(key: AppConstants.keyAuthToken, value: token);

  Future<void> saveUserId(String userId) =>
      secureStorage.write(key: AppConstants.keyUserId, value: userId);

  Future<void> savePhone(String phone) =>
      secureStorage.write(key: AppConstants.keyUserPhone, value: phone);

  Future<void> savePin(String pinHash) =>
      secureStorage.write(key: AppConstants.keyUserPin, value: pinHash);

  Future<void> setLoggedOut(bool value) => secureStorage.write(
        key: AppConstants.keyHasBeenLoggedOut,
        value: value.toString(),
      );

  Future<String?> getToken() =>
      secureStorage.read(key: AppConstants.keyAuthToken);

  Future<String?> getSavedPhone() =>
      secureStorage.read(key: AppConstants.keyUserPhone);

  Future<bool> hasBeenLoggedOut() async {
    final val = await secureStorage.read(key: AppConstants.keyHasBeenLoggedOut);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserProfile);
  }
}
DART
echo "  ✅ local_datasource.dart"

cat > lib/features/auth/data/repository_impl.dart << 'DART'
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../domain/models/user_model.dart';
import '../domain/repository.dart';
import 'local_datasource.dart';
import 'remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remote;
  final AuthLocalDatasource local;

  const AuthRepositoryImpl({required this.remote, required this.local});

  @override
  Future<({String token, String userId, bool needsOtp})> login({
    required String phone,
    required String pinHash,
  }) async {
    try {
      final res = await remote.login(phone: phone, pinHash: pinHash);
      return (token: res.token, userId: res.userId, needsOtp: res.needsOtp);
    } on InvalidCredentialsException {
      throw const InvalidCredentialsFailure();
    } on TooManyAttemptsException {
      throw const TooManyAttemptsFailure();
    } on NetworkException {
      throw const NetworkFailure();
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> register({
    required String phone,
    required String nom,
    required String registre,
    required DateTime dateNaissance,
    required String communeId,
  }) async {
    try {
      await remote.register(
        phone: phone,
        nom: nom,
        registre: registre,
        dateNaissance: dateNaissance.toIso8601String().split('T').first,
        communeId: communeId,
      );
    } on PhoneAlreadyExistsException {
      throw const PhoneAlreadyExistsFailure();
    } on NetworkException {
      throw const NetworkFailure();
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<String> verifyOtp({required String phone, required String code}) async {
    try {
      return await remote.verifyOtp(phone: phone, code: code);
    } on InvalidOtpException {
      throw const InvalidOtpFailure();
    } on NetworkException {
      throw const NetworkFailure();
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> resendOtp({required String phone}) async {
    try {
      await remote.resendOtp(phone: phone);
    } on NetworkException {
      throw const NetworkFailure();
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final res = await remote.getMe();
      return res.toDomain();
    } on UnauthorizedException {
      throw const UnauthorizedFailure();
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override Future<void> saveToken(String token) => local.saveToken(token);
  @override Future<void> saveUserId(String id) => local.saveUserId(id);
  @override Future<void> savePhone(String phone) => local.savePhone(phone);
  @override Future<void> savePin(String pinHash) => local.savePin(pinHash);
  @override Future<void> setLoggedOut(bool v) => local.setLoggedOut(v);
  @override Future<String?> getToken() => local.getToken();
  @override Future<String?> getSavedPhone() => local.getSavedPhone();
  @override Future<bool> hasBeenLoggedOut() => local.hasBeenLoggedOut();
  @override Future<void> logout() => local.clearAll();
}
DART
echo "  ✅ repository_impl.dart"

# ════════════════════════════════════════════════════════════
# PRESENTATION — PROVIDERS
# ════════════════════════════════════════════════════════════

cat > lib/features/auth/presentation/providers/auth_provider.dart << 'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/local_datasource.dart';
import '../../data/remote_datasource.dart';
import '../../data/repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/resend_otp_usecase.dart';

// ── Providers infrastructure ──────────────────────────────

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final _authLocalProvider = Provider<AuthLocalDatasource>((ref) =>
    AuthLocalDatasource(secureStorage: ref.read(_secureStorageProvider)));

final _authRemoteProvider = Provider<AuthRemoteDatasource>((ref) =>
    AuthRemoteDatasource(client: ref.read(dioClientProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(
      remote: ref.read(_authRemoteProvider),
      local: ref.read(_authLocalProvider),
    ));

// ── Providers usecases ────────────────────────────────────

final loginUsecaseProvider = Provider<LoginUsecase>(
    (ref) => LoginUsecase(ref.read(authRepositoryProvider)));

final registerUsecaseProvider = Provider<RegisterUsecase>(
    (ref) => RegisterUsecase(ref.read(authRepositoryProvider)));

final verifyOtpUsecaseProvider = Provider<VerifyOtpUsecase>(
    (ref) => VerifyOtpUsecase(ref.read(authRepositoryProvider)));

final resendOtpUsecaseProvider = Provider<ResendOtpUsecase>(
    (ref) => ResendOtpUsecase(ref.read(authRepositoryProvider)));

// ── État auth ─────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isAuthenticated,
    bool clearError = false,
  }) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        user: user ?? this.user,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUsecase _login;
  final RegisterUsecase _register;
  final VerifyOtpUsecase _verifyOtp;
  final ResendOtpUsecase _resendOtp;
  final AuthRepository _repo;

  AuthNotifier({
    required LoginUsecase login,
    required RegisterUsecase register,
    required VerifyOtpUsecase verifyOtp,
    required ResendOtpUsecase resendOtp,
    required AuthRepository repo,
  })  : _login = login,
        _register = register,
        _verifyOtp = verifyOtp,
        _resendOtp = resendOtp,
        _repo = repo,
        super(const AuthState());

  void clearError() => state = state.copyWith(clearError: true);

  Future<({bool needsOtp})> login({
    required String phone,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _login(phone: phone, pin: pin);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: !result.needsOtp,
      );
      return (needsOtp: result.needsOtp);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String phone,
    required String nom,
    required String registre,
    required DateTime dateNaissance,
    required String communeId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _register(
        phone: phone, nom: nom, registre: registre,
        dateNaissance: dateNaissance, communeId: communeId,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _verifyOtp(phone: phone, code: code);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> resendOtp({required String phone}) async {
    try {
      await _resendOtp(phone: phone);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) =>
    AuthNotifier(
      login: ref.read(loginUsecaseProvider),
      register: ref.read(registerUsecaseProvider),
      verifyOtp: ref.read(verifyOtpUsecaseProvider),
      resendOtp: ref.read(resendOtpUsecaseProvider),
      repo: ref.read(authRepositoryProvider),
    ));

// ── Provider données inscription (transit entre étapes) ──

class RegistrationData {
  final String nom;
  final String registre;
  final DateTime? dateNaissance;
  final String phone;
  final String? communeId;
  final String? communeNom;
  final String? regionId;
  final String? departementId;

  const RegistrationData({
    this.nom = '',
    this.registre = '',
    this.dateNaissance,
    this.phone = '',
    this.communeId,
    this.communeNom,
    this.regionId,
    this.departementId,
  });

  RegistrationData copyWith({
    String? nom, String? registre, DateTime? dateNaissance,
    String? phone, String? communeId, String? communeNom,
    String? regionId, String? departementId,
  }) => RegistrationData(
        nom: nom ?? this.nom,
        registre: registre ?? this.registre,
        dateNaissance: dateNaissance ?? this.dateNaissance,
        phone: phone ?? this.phone,
        communeId: communeId ?? this.communeId,
        communeNom: communeNom ?? this.communeNom,
        regionId: regionId ?? this.regionId,
        departementId: departementId ?? this.departementId,
      );

  Map<String, dynamic> toMap() => {
        'nom': nom, 'registre': registre,
        'phone': phone, 'communeId': communeId,
        'communeNom': communeNom,
      };

  bool get isStep1Valid =>
      nom.trim().isNotEmpty &&
      registre.trim().isNotEmpty &&
      dateNaissance != null &&
      phone.trim().isNotEmpty;

  bool get isStep2Valid => communeId != null && communeId!.isNotEmpty;
}

final registrationDataProvider =
    StateNotifierProvider<RegistrationDataNotifier, RegistrationData>(
        (_) => RegistrationDataNotifier());

class RegistrationDataNotifier extends StateNotifier<RegistrationData> {
  RegistrationDataNotifier() : super(const RegistrationData());

  void update(RegistrationData Function(RegistrationData) updater) {
    state = updater(state);
  }

  void reset() => state = const RegistrationData();
}
DART
echo "  ✅ auth_provider.dart"

# ════════════════════════════════════════════════════════════
# SCREENS
# ════════════════════════════════════════════════════════════

# ── S01 Splash Screen ────────────────────────────────────────
cat > lib/features/auth/presentation/screens/splash_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// S01 — Splash Screen
/// Logo centré sur fond navy, tagline, barre de chargement verte.
/// Après 2 secondes : redirect selon état auth.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.getToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo baobab
                        SvgPicture.asset(
                          Assets.logoTeranga,
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 24),
                        // Nom app
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TERANGA ',
                              style: AppTextStyles.appNameBold.copyWith(
                                color: AppColors.textOnPrimary,
                                fontSize: 26,
                              ),
                            ),
                            Text(
                              'CIVIL',
                              style: AppTextStyles.appNameRegular.copyWith(
                                color: AppColors.textOnPrimary,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Séparateur vert
                        Container(
                          width: 40,
                          height: 2,
                          color: AppColors.secondary,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        // Tagline
                        Text(
                          AppConstants.appTagline,
                          style: AppTextStyles.tagline.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Barre de chargement verte en bas
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chargement...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART
echo "  ✅ splash_screen.dart"

# ── S02 Login Screen ─────────────────────────────────────────
cat > lib/features/auth/presentation/screens/login_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/assets_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

/// S02 — Écran de connexion
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtr = TextEditingController();
  final _pinCtr = TextEditingController();
  bool _formValid = false;

  @override
  void dispose() {
    _phoneCtr.dispose();
    _pinCtr.dispose();
    super.dispose();
  }

  void _checkValidity() {
    setState(() {
      _formValid = _phoneCtr.text.trim().length >= 9 &&
          _pinCtr.text.length == AppConstants.pinLength;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    try {
      final result = await auth.login(
        phone: _phoneCtr.text.trim(),
        pin: _pinCtr.text,
      );
      if (!mounted) return;
      if (result.needsOtp) {
        context.push(AppRoutes.otpVerification, extra: _phoneCtr.text.trim());
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _showError(Object e) {
    String msg = 'Une erreur est survenue.';
    if (e is InvalidCredentialsFailure) msg = e.message;
    else if (e is NetworkFailure) msg = e.message;
    else if (e is TooManyAttemptsFailure) msg = e.message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            onChanged: _checkValidity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Logo
                SvgPicture.asset(Assets.logoTeranga, width: 72, height: 72),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('TERANGA ', style: AppTextStyles.appNameBold),
                    Text('CIVIL', style: AppTextStyles.appNameRegular),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.tagline,
                ),
                const SizedBox(height: 40),
                // Titre
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Se connecter', style: AppTextStyles.headlineLarge),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Accédez à vos services civils en ligne',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: 28),
                // Champ téléphone
                PhoneTextField(
                  controller: _phoneCtr,
                  onChanged: (_) => _checkValidity(),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                // Champ PIN
                AppTextField(
                  label: 'Code PIN',
                  hint: '••••••',
                  controller: _pinCtr,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: AppConstants.pinLength,
                  onChanged: (_) => _checkValidity(),
                  onSubmitted: (_) => _formValid ? _submit() : null,
                ),
                const SizedBox(height: 8),
                // Lien mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: LinkButton(
                    label: 'Code PIN oublié ?',
                    onPressed: () {/* TODO */},
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                // Bouton connexion
                PrimaryButton(
                  label: 'Se connecter',
                  onPressed: _submit,
                  isLoading: isLoading,
                  isEnabled: _formValid,
                ),
                const SizedBox(height: 24),
                // Lien inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    LinkButton(
                      label: "S'inscrire",
                      onPressed: () => context.push(AppRoutes.registerStep1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ login_screen.dart"

# ── S02B OTP Verification ────────────────────────────────────
cat > lib/features/auth/presentation/screens/otp_verification_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../providers/auth_provider.dart';

/// S02B — Vérification SMS (reconnexion après déconnexion)
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _otpCtr = TextEditingController();
  bool _otpComplete = false;
  bool _hasError = false;

  @override
  void dispose() {
    _otpCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _hasError = false);
    try {
      await ref.read(authProvider.notifier).verifyOtp(
            phone: widget.phone,
            code: _otpCtr.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _hasError = true);
      if (!mounted) return;
      String msg = 'Code invalide.';
      if (e is InvalidOtpFailure) msg = e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authProvider.notifier).resendOtp(phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code renvoyé avec succès.')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification de sécurité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Code envoyé', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Un code à 6 chiffres a été envoyé au\n${AppFormatters.phoneNumber(widget.phone)}',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              Center(
                child: OtpInput(
                  controller: _otpCtr,
                  hasError: _hasError,
                  onChanged: (v) => setState(() {
                    _otpComplete = v.length == 6;
                    if (_hasError) _hasError = false;
                  }),
                  onCompleted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 16),
              if (_hasError)
                Center(
                  child: Text(
                    'Code incorrect. Veuillez réessayer.',
                    style: AppTextStyles.inputError,
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: OtpResendRow(onResend: _resend),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirmer et accéder',
                onPressed: _submit,
                isLoading: isLoading,
                isEnabled: _otpComplete,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
DART
echo "  ✅ otp_verification_screen.dart"

# ── S03 Inscription Étape 1 ──────────────────────────────────
cat > lib/features/auth/presentation/screens/register_step1_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/document_scanner.dart';
import '../providers/auth_provider.dart';

/// S03 — Inscription Étape 1/4 : Identité
class RegisterStep1Screen extends ConsumerStatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  ConsumerState<RegisterStep1Screen> createState() =>
      _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends ConsumerState<RegisterStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();
  final _registreCtr = TextEditingController();
  final _phoneCtr = TextEditingController();
  DateTime? _dateNaissance;
  bool _scanSelected = false;
  bool _manualSelected = true;

  @override
  void dispose() {
    _nomCtr.dispose();
    _registreCtr.dispose();
    _phoneCtr.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nomCtr.text.trim().isNotEmpty &&
      _registreCtr.text.trim().isNotEmpty &&
      _phoneCtr.text.trim().length >= 9 &&
      _dateNaissance != null;

  Future<void> _handleScan() async {
    final path = await ImagePickerHelper.showSourcePicker(context);
    if (path != null) {
      // TODO: connecter l'OCR backend quand disponible
      // Pour l'instant on affiche le formulaire pré-rempli vide
      setState(() {
        _scanSelected = true;
        _manualSelected = false;
      });
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(registrationDataProvider.notifier).update((d) => d.copyWith(
          nom: _nomCtr.text.trim(),
          registre: _registreCtr.text.trim().toUpperCase(),
          dateNaissance: _dateNaissance,
          phone: _phoneCtr.text.trim(),
        ));
    context.push(AppRoutes.registerStep2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer mon compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Étape 1/4 — Identité',
                          style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Renseignez vos informations personnelles',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      // Cards choix scan / manuel
                      DocumentScannerCard(
                        title: 'Scanner ma CNI',
                        subtitle: 'OCR — remplissage automatique (optionnel)',
                        icon: Icons.document_scanner_outlined,
                        isSelected: _scanSelected,
                        onTap: _handleScan,
                      ),
                      const SizedBox(height: 12),
                      DocumentScannerCard(
                        title: 'Remplir manuellement',
                        subtitle: 'Saisir mes informations directement',
                        icon: Icons.edit_outlined,
                        isSelected: _manualSelected,
                        onTap: () => setState(() {
                          _manualSelected = true;
                          _scanSelected = false;
                        }),
                      ),
                      const SizedBox(height: 28),
                      // Formulaire
                      AppTextField(
                        label: 'Nom complet',
                        hint: 'Ex: Amadou Diallo',
                        controller: _nomCtr,
                        validator: Validators.fullName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Numéro de registre (CNI)',
                        hint: 'Ex: SN-123456-A',
                        controller: _registreCtr,
                        validator: Validators.registreNumber,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      DateTextField(
                        label: 'Date de naissance',
                        selectedDate: _dateNaissance,
                        validator: (_) => Validators.dateNaissance(_dateNaissance),
                        lastDate: DateTime.now(),
                        onDateSelected: (d) =>
                            setState(() => _dateNaissance = d),
                      ),
                      const SizedBox(height: 16),
                      PhoneTextField(
                        controller: _phoneCtr,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Suivant →',
                onPressed: _next,
                isEnabled: _isValid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: AppColors.border,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: step / 4,
        child: Container(color: AppColors.secondary),
      ),
    );
  }
}
DART
echo "  ✅ register_step1_screen.dart"

# ── S04 Inscription Étape 2 ──────────────────────────────────
cat > lib/features/auth/presentation/screens/register_step2_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/cascaded_commune_select.dart';
import '../../../../shared/models/commune_model.dart';
import '../providers/auth_provider.dart';

/// S04 — Inscription Étape 2/4 : Commune
class RegisterStep2Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep2Screen({super.key, required this.registrationData});

  @override
  ConsumerState<RegisterStep2Screen> createState() =>
      _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends ConsumerState<RegisterStep2Screen> {
  CommuneModel? _commune;
  RegionModel? _region;
  DepartementModel? _departement;

  bool get _isValid => _commune != null;

  void _next() {
    if (_commune == null) return;
    ref.read(registrationDataProvider.notifier).update((d) => d.copyWith(
          communeId: _commune!.id,
          communeNom: _commune!.nom,
          regionId: _region?.id,
          departementId: _departement?.id,
        ));
    context.push(AppRoutes.registerStep3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer mon compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Étape 2/4 — Commune',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Sélectionnez la commune où vous êtes officiellement déclaré(e)',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    CascadedCommuneSelect(
                      onChanged: (r, d, c) => setState(() {
                        _region = r;
                        _departement = d;
                        _commune = c;
                      }),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusBlueLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppColors.statusBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cette information est vérifiée auprès des registres officiels.',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.statusBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Valider et envoyer le code SMS →',
                onPressed: _next,
                isEnabled: _isValid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: AppColors.border,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: step / 4,
        child: Container(color: AppColors.secondary),
      ),
    );
  }
}
DART
echo "  ✅ register_step2_screen.dart"

# ── S05 Inscription Étape 3 ──────────────────────────────────
cat > lib/features/auth/presentation/screens/register_step3_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../providers/auth_provider.dart';

/// S05 — Inscription Étape 3/4 : Validation SMS
class RegisterStep3Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep3Screen({super.key, required this.registrationData});

  @override
  ConsumerState<RegisterStep3Screen> createState() =>
      _RegisterStep3ScreenState();
}

class _RegisterStep3ScreenState extends ConsumerState<RegisterStep3Screen> {
  final _otpCtr = TextEditingController();
  bool _otpComplete = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    final data = ref.read(registrationDataProvider);
    try {
      await ref.read(authProvider.notifier).register(
            phone: data.phone,
            nom: data.nom,
            registre: data.registre,
            dateNaissance: data.dateNaissance!,
            communeId: data.communeId!,
          );
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erreur lors de l\'envoi du code.';
      if (e is PhoneAlreadyExistsFailure) msg = e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _verify() async {
    setState(() => _hasError = false);
    final data = ref.read(registrationDataProvider);
    try {
      await ref.read(authProvider.notifier).verifyOtp(
            phone: data.phone,
            code: _otpCtr.text,
          );
      if (!mounted) return;
      context.push(AppRoutes.registerStep4);
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _resend() async {
    final data = ref.read(registrationDataProvider);
    await ref.read(authProvider.notifier).resendOtp(phone: data.phone);
  }

  @override
  void dispose() {
    _otpCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(registrationDataProvider);
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer mon compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: 3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Étape 3/4 — Vérification',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Un code à 6 chiffres a été envoyé au\n${AppFormatters.phoneNumber(data.phone)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: OtpInput(
                        controller: _otpCtr,
                        hasError: _hasError,
                        onChanged: (v) => setState(() {
                          _otpComplete = v.length == 6;
                          if (_hasError) _hasError = false;
                        }),
                        onCompleted: (_) => _verify(),
                      ),
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Code incorrect. Veuillez réessayer.',
                          style: AppTextStyles.inputError,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Center(child: OtpResendRow(onResend: _resend)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Valider mon compte →',
                onPressed: _verify,
                isLoading: isLoading,
                isEnabled: _otpComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});
  @override
  Widget build(BuildContext context) => Container(
        height: 4,
        color: AppColors.border,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: step / 4,
          child: Container(color: AppColors.secondary),
        ),
      );
}
DART
echo "  ✅ register_step3_screen.dart"

# ── S06 Inscription Étape 4 ──────────────────────────────────
cat > lib/features/auth/presentation/screens/register_step4_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// S06 — Inscription Étape 4/4 : Création code PIN
class RegisterStep4Screen extends ConsumerStatefulWidget {
  final Map<String, dynamic> registrationData;
  const RegisterStep4Screen({super.key, required this.registrationData});

  @override
  ConsumerState<RegisterStep4Screen> createState() =>
      _RegisterStep4ScreenState();
}

class _RegisterStep4ScreenState extends ConsumerState<RegisterStep4Screen> {
  final List<String> _pin = [];
  final List<String> _confirm = [];
  bool _confirming = false;
  String? _error;

  bool get _isComplete =>
      _confirming ? _confirm.length == 6 : _pin.length == 6;

  void _onKeyTap(String digit) {
    setState(() {
      _error = null;
      final current = _confirming ? _confirm : _pin;
      if (current.length < 6) current.add(digit);

      // Premier PIN complet → passer à la confirmation
      if (!_confirming && _pin.length == 6) {
        final err = Validators.pin(_pin.join());
        if (err != null) {
          _error = err;
          _pin.clear();
        } else {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => _confirming = true);
          });
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      final current = _confirming ? _confirm : _pin;
      if (current.isNotEmpty) current.removeLast();
    });
  }

  void _submit() {
    final pinStr = _pin.join();
    final confirmStr = _confirm.join();
    if (pinStr != confirmStr) {
      setState(() {
        _error = 'Les deux codes PIN ne correspondent pas.';
        _confirm.clear();
        _confirming = true;
      });
      return;
    }
    // Tout est bon → aller au dashboard
    ref.read(registrationDataProvider.notifier).reset();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final displayPin = _confirming ? _confirm : _pin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer mon compte'),
        leading: _confirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => setState(() {
                  _confirming = false;
                  _confirm.clear();
                  _error = null;
                }),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => context.pop(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      _confirming
                          ? 'Confirmez votre code PIN'
                          : 'Choisissez votre code PIN',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _confirming
                          ? 'Ressaisissez le même code pour confirmer'
                          : 'Ce code vous servira à vous connecter à chaque session',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Points PIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) => _PinDot(filled: i < displayPin.length)),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.inputError),
                    ],
                    const SizedBox(height: 32),
                    // Clavier numérique
                    _NumericKeypad(
                      onDigit: _onKeyTap,
                      onDelete: _onDelete,
                    ),
                    const Spacer(),
                    if (_confirming && _confirm.length == 6)
                      PrimaryButton(
                        label: 'Confirmer et accéder à mon compte',
                        onPressed: _submit,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool filled;
  const _PinDot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : AppColors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumericKeypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.map((key) {
          if (key.isEmpty) return const SizedBox(width: 80, height: 64);
          return _KeyButton(
            label: key,
            onTap: () => key == '⌫' ? onDelete() : onDigit(key),
            isDelete: key == '⌫',
          );
        }).toList(),
      )).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 64,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: isDelete
              ? const Icon(Icons.backspace_outlined,
                  color: AppColors.textSecondary, size: 22)
              : Text(
                  label,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});
  @override
  Widget build(BuildContext context) => Container(
        height: 4,
        color: AppColors.border,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: step / 4,
          child: Container(color: AppColors.secondary),
        ),
      );
}
DART
echo "  ✅ register_step4_screen.dart"

echo ""
echo "✅ Étape 5 terminée — 14 fichiers créés"
echo ""
echo "Fichiers générés :"
echo "  lib/features/auth/domain/models/user_model.dart"
echo "  lib/features/auth/domain/repository.dart"
echo "  lib/features/auth/domain/usecases/login_usecase.dart"
echo "  lib/features/auth/domain/usecases/register_usecase.dart"
echo "  lib/features/auth/domain/usecases/verify_otp_usecase.dart"
echo "  lib/features/auth/domain/usecases/resend_otp_usecase.dart"
echo "  lib/features/auth/data/models/auth_response_model.dart"
echo "  lib/features/auth/data/remote_datasource.dart"
echo "  lib/features/auth/data/local_datasource.dart"
echo "  lib/features/auth/data/repository_impl.dart"
echo "  lib/features/auth/presentation/providers/auth_provider.dart"
echo "  lib/features/auth/presentation/screens/splash_screen.dart"
echo "  lib/features/auth/presentation/screens/login_screen.dart"
echo "  lib/features/auth/presentation/screens/otp_verification_screen.dart"
echo "  lib/features/auth/presentation/screens/register_step1_screen.dart"
echo "  lib/features/auth/presentation/screens/register_step2_screen.dart"
echo "  lib/features/auth/presentation/screens/register_step3_screen.dart"
echo "  lib/features/auth/presentation/screens/register_step4_screen.dart"
echo ""
echo "⚠️  Ajouter dans pubspec.yaml si absent :"
echo "     crypto: ^3.0.3"
