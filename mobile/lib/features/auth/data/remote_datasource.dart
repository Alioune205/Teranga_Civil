import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/auth_response_model.dart';

/// Datasource distante pour l'authentification — communique avec le
/// backend Django "SUNU CIVIL" via l'enveloppe standard
/// `{success, message, data, errors}`.
class AuthRemoteDatasource {
  final DioClient client;
  const AuthRemoteDatasource({required this.client});

  /// POST /api/auth/login/
  ///
  /// Retourne soit des tokens (compte vérifié), soit une demande de
  /// code OTP (`needs_otp: true`) si le compte n'est pas encore vérifié.
  Future<LoginResultModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      // Le backend (CustomTokenObtainPairSerializer) attend le champ
      // `email` comme nom de champ (USERNAME_FIELD = 'email'), même s'il
      // accepte indifféremment un email ou un numéro de téléphone comme
      // valeur. Envoyer `identifier` ferait échouer la validation côté
      // backend (champ `email` manquant) avec un 401 générique.
      final res = await client.post('/auth/login/', data: {
        'email': identifier,
        'password': password,
      });

      final data = _unwrap(res);

      if (data['needs_otp'] == true) {
        return LoginResultModel.needsOtp(NeedsOtpResponseModel.fromJson(data));
      }

      return LoginResultModel.tokens(AuthTokenResponseModel.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          e.error is UnauthorizedException) {
        throw const InvalidCredentialsException();
      }
      rethrow;
    }
  }

  /// POST /api/auth/register/
  ///
  /// Le backend crée le compte (non vérifié) et envoie un code OTP.
  Future<LoginResultModel> register({
    required String prenom,
    required String nom,
    required String password,
    String? phone,
    String? email,
  }) async {
    try {
      final res = await client.post('/auth/register/', data: {
        'first_name': prenom,
        'last_name': nom,
        'password': password,
        'password_confirm': password,
        // On envoie toujours `phone` (null si absent). Sinon le backend met
        // '' par défaut, ce qui viole la contrainte UNIQUE sur phone (un seul
        // '' possible) → 500 dès la 2e inscription par email. Un null explicite
        // force un NULL en base (autorisé en plusieurs exemplaires).
        'phone': (phone != null && phone.isNotEmpty) ? phone : null,
        if (email != null && email.isNotEmpty) 'email': email,
      });

      final data = _unwrap(res);
      // Selon la version du backend, l'inscription renvoie soit directement
      // des tokens (le compte est connecté immédiatement), soit
      // `needs_otp: true` avec un identifiant à vérifier par code OTP.
      if (data['needs_otp'] == true) {
        return LoginResultModel.needsOtp(NeedsOtpResponseModel.fromJson(data));
      }
      return LoginResultModel.tokens(AuthTokenResponseModel.fromJson(data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 400 && data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          final fieldError = errors['phone'] ?? errors['email'];
          if (fieldError != null) {
            final fieldMessage = (fieldError is List && fieldError.isNotEmpty)
                ? fieldError.first.toString()
                : fieldError.toString();
            final lower = fieldMessage.toLowerCase();
            // Ne mapper vers "déjà enregistré" que si le message indique
            // réellement un doublon (et non, par ex., un format invalide).
            if (lower.contains('existe déjà') ||
                lower.contains('déjà associé') ||
                lower.contains('déjà enregistr') ||
                lower.contains('already exists') ||
                lower.contains('unique')) {
              throw const PhoneAlreadyExistsException();
            }
            throw ApiException(message: fieldMessage, statusCode: 400);
          }
          // Autres erreurs de validation (mot de passe, champs requis, etc.)
          final message = _firstErrorMessage(errors) ??
              data['message'] as String? ??
              'Données invalides.';
          throw ApiException(message: message, statusCode: 400);
        }
      }
      rethrow;
    }
  }

  /// Extrait le premier message d'erreur d'un objet `errors` du type
  /// `{"password": ["..."], "first_name": ["..."]}`.
  String? _firstErrorMessage(Map<String, dynamic> errors) {
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// POST /api/auth/verify-otp/
  ///
  /// Valide le code OTP et retourne les tokens JWT + le profil utilisateur.
  Future<AuthTokenResponseModel> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    try {
      final res = await client.post('/auth/otp/verify/', data: {
        'identifier': identifier,
        'code': code,
      });

      final data = _unwrap(res);
      return AuthTokenResponseModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = _extractErrorMessage(e.response?.data) ??
            'Code OTP invalide ou expiré.';
        throw InvalidOtpException(message);
      }
      rethrow;
    }
  }

  /// Extrait un message d'erreur lisible depuis l'enveloppe
  /// `{success, message, data, errors}` (ou les erreurs DRF brutes
  /// `{"non_field_errors": ["..."]}`).
  String? _extractErrorMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      final msg = _firstErrorMessage(errors);
      if (msg != null) return msg;
    }
    if (errors is List && errors.isNotEmpty) return errors.first.toString();
    return data['message'] as String?;
  }

  /// POST /api/auth/otp/send/
  Future<String?> resendOtp({required String identifier}) async {
    final res = await client.post('/auth/otp/send/', data: {
      'identifier': identifier,
    });
    final data = _unwrap(res);
    return data['otp_debug']?.toString();
  }

  /// POST /api/auth/refresh/
  Future<String> refreshToken({required String refresh}) async {
    try {
      final res = await client.post('/auth/refresh/', data: {
        'refresh': refresh,
      });
      final data = _unwrap(res);
      return data['access'] as String? ?? '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      rethrow;
    }
  }

  /// GET /api/users/me/
  Future<UserResponseModel> getMe() async {
    try {
      final res = await client.get('/users/me/');
      final data = _unwrap(res);
      return UserResponseModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          e.error is UnauthorizedException) {
        throw const UnauthorizedException();
      }
      rethrow;
    }
  }

  /// Déballe l'enveloppe standard `{success, message, data, errors}`.
  Map<String, dynamic> _unwrap(Response res) {
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) return inner;
      if (inner == null) return const {};
    }
    if (body is Map<String, dynamic>) return body;
    throw const ApiException(message: 'Réponse invalide.');
  }
}
