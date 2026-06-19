import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class AuthLocalDatasource {
  final FlutterSecureStorage secureStorage;
  const AuthLocalDatasource({required this.secureStorage});

  Future<void> saveToken(String token) =>
      secureStorage.write(key: AppConstants.keyAuthToken, value: token);

  Future<void> saveRefreshToken(String token) => secureStorage.write(
      key: AppConstants.keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      secureStorage.read(key: AppConstants.keyRefreshToken);

  Future<void> saveUserId(String userId) =>
      secureStorage.write(key: AppConstants.keyUserId, value: userId);

  Future<void> saveIdentifier(String identifier) =>
      secureStorage.write(key: AppConstants.keyUserPhone, value: identifier);

  Future<void> setLoggedOut(bool value) => secureStorage.write(
        key: AppConstants.keyHasBeenLoggedOut,
        value: value.toString(),
      );

  Future<String?> getToken() =>
      secureStorage.read(key: AppConstants.keyAuthToken);

  Future<String?> getSavedIdentifier() =>
      secureStorage.read(key: AppConstants.keyUserPhone);

  Future<bool> hasBeenLoggedOut() async {
    final val =
        await secureStorage.read(key: AppConstants.keyHasBeenLoggedOut);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserProfile);
  }
}
