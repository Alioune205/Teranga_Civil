import 'package:dio/dio.dart';
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
  Future<({bool needsOtp, String identifier, UserModel? user})> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final result =
          await remote.login(identifier: identifier, password: password);

      if (result.needsOtp) {
        final otpInfo = result.otpInfo!;
        return (
          needsOtp: true,
          identifier: otpInfo.identifier,
          user: otpInfo.user?.toDomain(),
        );
      }

      final tokens = result.tokens!;
      await local.saveToken(tokens.access);
      await local.saveRefreshToken(tokens.refresh);
      await local.saveUserId(tokens.user.id);
      await local.saveIdentifier(identifier);

      return (
        needsOtp: false,
        identifier: identifier,
        user: tokens.user.toDomain(),
      );
    } on InvalidCredentialsException {
      throw const InvalidCredentialsFailure();
    } on TooManyAttemptsException {
      throw const TooManyAttemptsFailure();
    } on NetworkException {
      throw const NetworkFailure();
    } on TimeoutException catch (e) {
      throw ServerFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on ApiException catch (e) {
      throw ApiFailure(message: e.message, statusCode: e.statusCode, code: e.errorCode);
    } on NotFoundException catch (e) {
      throw ApiFailure(message: e.message, statusCode: 404);
    } on ForbiddenException catch (e) {
      throw ApiFailure(message: e.message, statusCode: 403);
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      // Filet de sécurité : toute DioException non mappée par le
      // datasource (ex. 429 throttling, erreurs réseau brutes) est
      // convertie ici en Failure exploitable par l'UI, au lieu de
      // tomber dans le `catch (_)` générique ci-dessous.
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const InvalidCredentialsFailure();
      }
      if (status == 429) {
        throw const TooManyAttemptsFailure();
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ServerFailure(
            message: 'La requête a expiré. Réessayez.');
      }
      final data = e.response?.data;
      final msg = (data is Map<String, dynamic>)
          ? (data['message'] as String? ?? data['detail'] as String?)
          : null;
      throw ApiFailure(message: msg ?? 'Une erreur est survenue.', statusCode: status);
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<({bool needsOtp, String identifier, String? otpDebug, UserModel? user})>
      register({
    required String prenom,
    required String nom,
    required String password,
    String? phone,
    String? email,
  }) async {
    try {
      final result = await remote.register(
        prenom: prenom,
        nom: nom,
        password: password,
        phone: phone,
        email: email,
      );

      // Le backend exige encore une vérification OTP : aucun token stocké.
      if (result.needsOtp) {
        final otp = result.otpInfo!;
        return (
          needsOtp: true,
          identifier: otp.identifier,
          otpDebug: otp.otpDebug,
          user: otp.user?.toDomain(),
        );
      }

      // Le backend a renvoyé des tokens : on connecte directement l'utilisateur.
      final tokens = result.tokens!;
      await local.saveToken(tokens.access);
      await local.saveRefreshToken(tokens.refresh);
      await local.saveUserId(tokens.user.id);
      await local.saveIdentifier(phone ?? email ?? '');
      return (
        needsOtp: false,
        identifier: phone ?? email ?? '',
        otpDebug: null,
        user: tokens.user.toDomain(),
      );
    } on PhoneAlreadyExistsException {
      throw const PhoneAlreadyExistsFailure();
    } on NetworkException {
      throw const NetworkFailure();
    } on TimeoutException catch (e) {
      throw ServerFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on ApiException catch (e) {
      throw ValidationFailure(message: e.message);
    } on Failure {
      rethrow;
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String identifier,
    required String code,
  }) async {
    try {
      final tokens =
          await remote.verifyOtp(identifier: identifier, code: code);
      await local.saveToken(tokens.access);
      await local.saveRefreshToken(tokens.refresh);
      await local.saveUserId(tokens.user.id);
      await local.saveIdentifier(identifier);
      return tokens.user.toDomain();
    } on InvalidOtpException catch (e) {
      throw InvalidOtpFailure(message: e.message);
    } on NetworkException {
      throw const NetworkFailure();
    } catch (_) {
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<String?> resendOtp({required String identifier}) async {
    try {
      return await remote.resendOtp(identifier: identifier);
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

  @override Future<void> saveToken(String t) => local.saveToken(t);
  @override Future<void> saveRefreshToken(String t) => local.saveRefreshToken(t);
  @override Future<void> saveUserId(String id) => local.saveUserId(id);
  @override Future<void> saveIdentifier(String i) => local.saveIdentifier(i);
  @override Future<void> setLoggedOut(bool v) => local.setLoggedOut(v);
  @override Future<String?> getToken() => local.getToken();
  @override Future<String?> getRefreshToken() => local.getRefreshToken();
  @override Future<String?> getSavedIdentifier() => local.getSavedIdentifier();
  @override Future<bool> hasBeenLoggedOut() => local.hasBeenLoggedOut();
  @override Future<void> logout() => local.clearAll();
}
