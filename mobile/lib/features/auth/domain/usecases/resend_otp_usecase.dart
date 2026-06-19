import '../repository.dart';

class ResendOtpUsecase {
  final AuthRepository repository;
  const ResendOtpUsecase(this.repository);

  /// Retourne le nouveau code OTP de debug (mode DEBUG uniquement, sinon
  /// `null`).
  Future<String?> call({required String identifier}) =>
      repository.resendOtp(identifier: identifier);
}
