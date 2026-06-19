abstract class Failure {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// ── Réseau & API ─────────────────────────────────────────────────────────────
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Pas de connexion internet. Vérifiez votre réseau.',
    super.code = 'NO_NETWORK',
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Le serveur est temporairement indisponible.',
    super.code = 'SERVER_ERROR',
  });
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure({required super.message, this.statusCode, super.code});
}

// ── Auth ──────────────────────────────────────────────────────────────────────
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Numéro de téléphone ou code PIN incorrect.',
    super.code = 'INVALID_CREDENTIALS',
  });
}

class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure({
    super.message = 'Code invalide ou expiré. Veuillez réessayer.',
    super.code = 'INVALID_OTP',
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expirée. Veuillez vous reconnecter.',
    super.code = 'UNAUTHORIZED',
  });
}

class PhoneAlreadyExistsFailure extends Failure {
  const PhoneAlreadyExistsFailure({
    super.message = 'Ce numéro est déjà associé à un compte.',
    super.code = 'PHONE_ALREADY_EXISTS',
  });
}

class TooManyAttemptsFailure extends Failure {
  const TooManyAttemptsFailure({
    super.message = 'Trop de tentatives. Réessayez dans quelques minutes.',
    super.code = 'TOO_MANY_ATTEMPTS',
  });
}

// ── Données locales ───────────────────────────────────────────────────────────
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erreur de stockage local.',
    super.code = 'CACHE_ERROR',
  });
}

class NotFoundLocalFailure extends Failure {
  const NotFoundLocalFailure({
    super.message = 'Données introuvables.',
    super.code = 'NOT_FOUND_LOCAL',
  });
}

// ── Validation ────────────────────────────────────────────────────────────────
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'VALIDATION_ERROR'});
}

// ── Dossiers ──────────────────────────────────────────────────────────────────
class DossierNotFoundFailure extends Failure {
  const DossierNotFoundFailure({
    super.message = 'Dossier introuvable.',
    super.code = 'DOSSIER_NOT_FOUND',
  });
}

class DownloadFailure extends Failure {
  const DownloadFailure({
    super.message = 'Impossible de télécharger le document.',
    super.code = 'DOWNLOAD_ERROR',
  });
}

// ── Paiement ─────────────────────────────────────────────────────────────────
class PaymentFailure extends Failure {
  const PaymentFailure({
    super.message = 'Le paiement a échoué. Vérifiez votre solde.',
    super.code = 'PAYMENT_FAILED',
  });
}

// ── Générique ─────────────────────────────────────────────────────────────────
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Une erreur inattendue est survenue.',
    super.code = 'UNEXPECTED_ERROR',
  });
}
