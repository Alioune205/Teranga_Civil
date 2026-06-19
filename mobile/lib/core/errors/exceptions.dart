class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Pas de connexion internet.']);
  @override String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'La requête a expiré.']);
  @override String toString() => 'TimeoutException: $message';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  const ApiException({required this.message, this.statusCode, this.errorCode});
  @override String toString() => 'ApiException($statusCode, $errorCode): $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Non autorisé.']);
  @override String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  const ForbiddenException([this.message = 'Accès refusé.']);
  @override String toString() => 'ForbiddenException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Ressource introuvable.']);
  @override String toString() => 'NotFoundException: $message';
}

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Erreur serveur.']);
  @override String toString() => 'ServerException: $message';
}

class InvalidCredentialsException implements Exception {
  final String message;
  const InvalidCredentialsException([this.message = 'Identifiants incorrects.']);
  @override String toString() => 'InvalidCredentialsException: $message';
}

class InvalidOtpException implements Exception {
  final String message;
  const InvalidOtpException([this.message = 'Code OTP invalide.']);
  @override String toString() => 'InvalidOtpException: $message';
}

class PhoneAlreadyExistsException implements Exception {
  final String message;
  const PhoneAlreadyExistsException([this.message = 'Numéro déjà enregistré.']);
  @override String toString() => 'PhoneAlreadyExistsException: $message';
}

class TooManyAttemptsException implements Exception {
  final String message;
  const TooManyAttemptsException([this.message = 'Trop de tentatives.']);
  @override String toString() => 'TooManyAttemptsException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Erreur de cache local.']);
  @override String toString() => 'CacheException: $message';
}

class FileSizeExceededException implements Exception {
  final String message;
  const FileSizeExceededException([this.message = 'Fichier trop volumineux.']);
  @override String toString() => 'FileSizeExceededException: $message';
}

class PaymentException implements Exception {
  final String message;
  const PaymentException([this.message = 'Erreur de paiement.']);
  @override String toString() => 'PaymentException: $message';
}

class UnexpectedException implements Exception {
  final String message;
  const UnexpectedException([this.message = 'Erreur inattendue.']);
  @override String toString() => 'UnexpectedException: $message';
}
