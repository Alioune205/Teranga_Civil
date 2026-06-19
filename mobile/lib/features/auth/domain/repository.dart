import 'models/user_model.dart';

abstract class AuthRepository {
  /// Connexion avec téléphone ou email + mot de passe.
  ///
  /// Si `needsOtp` est vrai, le compte n'est pas encore vérifié : un code
  /// OTP a été envoyé à `identifier` et aucun token n'est encore stocké.
  /// Sinon, `user` contient le profil et les tokens ont été sauvegardés.
  Future<({bool needsOtp, String identifier, UserModel? user})> login({
    required String identifier, // téléphone ou email
    required String password,
  });

  /// Inscription. Selon le backend, le compte peut être connecté
  /// immédiatement (tokens stockés, `needsOtp == false`, `user` rempli) ou
  /// nécessiter une vérification OTP (`needsOtp == true`, `identifier` à
  /// vérifier, `otpDebug` éventuel en mode DEBUG).
  Future<({bool needsOtp, String identifier, String? otpDebug, UserModel? user})>
      register({
    required String prenom,
    required String nom,
    required String password,
    String? phone,
    String? email,
  });

  /// Validation OTP (SMS ou email). Sauvegarde les tokens et retourne le
  /// profil utilisateur.
  Future<UserModel> verifyOtp({
    required String identifier,
    required String code,
  });

  /// Renvoie un nouveau code OTP. Retourne le code de debug (mode DEBUG
  /// uniquement, sinon `null`).
  Future<String?> resendOtp({required String identifier});

  Future<UserModel> getMe();

  // Stockage local
  Future<void> saveToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> saveUserId(String userId);
  Future<void> saveIdentifier(String identifier);
  Future<void> setLoggedOut(bool value);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<String?> getSavedIdentifier();
  Future<bool> hasBeenLoggedOut();
  Future<void> logout();
}
