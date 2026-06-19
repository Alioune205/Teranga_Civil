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

// ── Infrastructure ────────────────────────────────────────
final _secureStorageProvider =
    Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

final _authLocalProvider = Provider<AuthLocalDatasource>((ref) =>
    AuthLocalDatasource(secureStorage: ref.read(_secureStorageProvider)));

final _authRemoteProvider = Provider<AuthRemoteDatasource>((ref) =>
    AuthRemoteDatasource(client: ref.read(dioClientProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(
      remote: ref.read(_authRemoteProvider),
      local: ref.read(_authLocalProvider),
    ));

// ── Usecases ──────────────────────────────────────────────
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
  }) =>
      AuthState(
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

  /// Injecte le profil utilisateur dans l'état (appelé depuis splash)
  void setUser(UserModel user) {
    state = state.copyWith(user: user, isAuthenticated: true);
  }

  Future<({bool needsOtp, String identifier})> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _login(identifier: identifier, password: password);
      if (!result.needsOtp) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
        );
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
      return (needsOtp: result.needsOtp, identifier: result.identifier);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Inscription. Retourne l'identifiant à utiliser pour l'écran OTP
  /// (peut différer de la valeur saisie si un email placeholder a été
  /// généré côté backend pour une inscription par téléphone), ainsi que
  /// le code OTP de debug (mode DEBUG uniquement, sinon `null`).
  Future<({bool needsOtp, String identifier, String? otpDebug})> register({
    required String prenom,
    required String nom,
    required String password,
    String? phone,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _register(
        prenom: prenom,
        nom: nom,
        password: password,
        phone: phone,
        email: email,
      );
      if (!result.needsOtp) {
        // Le backend a directement connecté l'utilisateur (tokens stockés).
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return (
        needsOtp: result.needsOtp,
        identifier: result.identifier,
        otpDebug: result.otpDebug,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _verifyOtp(identifier: identifier, code: code);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<String?> resendOtp({required String identifier}) async {
    try {
      return await _resendOtp(identifier: identifier);
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

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(
          login: ref.read(loginUsecaseProvider),
          register: ref.read(registerUsecaseProvider),
          verifyOtp: ref.read(verifyOtpUsecaseProvider),
          resendOtp: ref.read(resendOtpUsecaseProvider),
          repo: ref.read(authRepositoryProvider),
        ));

// ── Données inscription en transit ────────────────────────
class RegistrationData {
  final String prenom;
  final String nom;
  final String password;
  final String? phone;
  final String? email;
  final bool usePhone; // true = téléphone, false = email

  const RegistrationData({
    this.prenom = '',
    this.nom = '',
    this.password = '',
    this.phone,
    this.email,
    this.usePhone = true,
  });

  String get identifier => usePhone ? (phone ?? '') : (email ?? '');

  RegistrationData copyWith({
    String? prenom,
    String? nom,
    String? password,
    String? phone,
    String? email,
    bool? usePhone,
  }) =>
      RegistrationData(
        prenom: prenom ?? this.prenom,
        nom: nom ?? this.nom,
        password: password ?? this.password,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        usePhone: usePhone ?? this.usePhone,
      );

  bool get isValid =>
      prenom.trim().isNotEmpty &&
      nom.trim().isNotEmpty &&
      password.length >= 6 &&
      (usePhone ? (phone?.isNotEmpty ?? false) : (email?.isNotEmpty ?? false));
}

final registrationDataProvider =
    StateNotifierProvider<RegistrationDataNotifier, RegistrationData>(
        (_) => RegistrationDataNotifier());

class RegistrationDataNotifier extends StateNotifier<RegistrationData> {
  RegistrationDataNotifier() : super(const RegistrationData());
  void update(RegistrationData Function(RegistrationData) fn) =>
      state = fn(state);
  void reset() => state = const RegistrationData();
}
