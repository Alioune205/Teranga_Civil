import '../models/user_model.dart';
import '../repository.dart';

class LoginUsecase {
  final AuthRepository repository;
  const LoginUsecase(this.repository);

  Future<({bool needsOtp, String identifier, UserModel? user})> call({
    required String identifier,
    required String password,
  }) =>
      repository.login(identifier: identifier, password: password);
}
