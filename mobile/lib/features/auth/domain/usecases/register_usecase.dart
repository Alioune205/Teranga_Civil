import '../models/user_model.dart';
import '../repository.dart';

class RegisterUsecase {
  final AuthRepository repository;
  const RegisterUsecase(this.repository);

  /// Selon le backend : compte connecté directement (`needsOtp == false`)
  /// ou vérification OTP requise (`needsOtp == true`).
  Future<({bool needsOtp, String identifier, String? otpDebug, UserModel? user})>
      call({
    required String prenom,
    required String nom,
    required String password,
    String? phone,
    String? email,
  }) =>
      repository.register(
        prenom: prenom,
        nom: nom,
        password: password,
        phone: phone,
        email: email,
      );
}
