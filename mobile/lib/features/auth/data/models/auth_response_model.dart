import '../../domain/models/user_model.dart';

/// Représentation utilisateur telle que renvoyée par le backend SUNU CIVIL
/// (`serialize_user()` / `UserSerializer`).
class UserResponseModel {
  final String id;
  final String? email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? role;
  final bool isVerified;
  final String? communeId;

  const UserResponseModel({
    required this.id,
    this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.role,
    this.isVerified = false,
    this.communeId,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) =>
      UserResponseModel(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        fullName: json['full_name'] as String?,
        role: json['role'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        communeId: json['commune']?.toString(),
      );

  UserModel toDomain() => UserModel(
        id: id,
        prenom: firstName,
        nom: lastName,
        phone: phone,
        email: email,
        isVerified: isVerified,
        role: role,
        communeId: communeId,
      );
}

/// Réponse `{access, refresh, user}` retournée par
/// /auth/login/ et /auth/verify-otp/ lorsque l'authentification réussit.
class AuthTokenResponseModel {
  final String access;
  final String refresh;
  final UserResponseModel user;

  const AuthTokenResponseModel({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthTokenResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthTokenResponseModel(
        access: json['access'] as String? ?? '',
        refresh: json['refresh'] as String? ?? '',
        user: UserResponseModel.fromJson(
            json['user'] as Map<String, dynamic>? ?? const {}),
      );
}

/// Réponse `{needs_otp, identifier, user, otp_debug?}` retournée par
/// /auth/register/, ou par /auth/login/ quand le compte n'est pas
/// encore vérifié.
class NeedsOtpResponseModel {
  final bool needsOtp;
  final String identifier;
  final UserResponseModel? user;
  final String? otpDebug;

  const NeedsOtpResponseModel({
    required this.needsOtp,
    required this.identifier,
    this.user,
    this.otpDebug,
  });

  factory NeedsOtpResponseModel.fromJson(Map<String, dynamic> json) =>
      NeedsOtpResponseModel(
        needsOtp: json['needs_otp'] as bool? ?? false,
        identifier: json['identifier'] as String? ?? '',
        user: json['user'] != null
            ? UserResponseModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        otpDebug: json['otp_debug']?.toString(),
      );
}

/// Résultat unifié d'une tentative de connexion : soit des tokens
/// (compte vérifié), soit une demande de code OTP (compte non vérifié).
class LoginResultModel {
  final bool needsOtp;
  final AuthTokenResponseModel? tokens;
  final NeedsOtpResponseModel? otpInfo;

  const LoginResultModel.tokens(this.tokens)
      : needsOtp = false,
        otpInfo = null;

  const LoginResultModel.needsOtp(this.otpInfo)
      : needsOtp = true,
        tokens = null;
}
