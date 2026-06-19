import '../models/user_model.dart';
import '../repository.dart';

class VerifyOtpUsecase {
  final AuthRepository repository;
  const VerifyOtpUsecase(this.repository);

  Future<UserModel> call({
    required String identifier,
    required String code,
  }) =>
      repository.verifyOtp(identifier: identifier, code: code);
}
