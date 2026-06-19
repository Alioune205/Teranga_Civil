import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/auth/data/models/auth_response_model.dart';
import 'package:teranga_civil/features/auth/domain/models/user_model.dart';

void main() {
  group('LoginResponseModel.fromJson', () {
    test('parse correctement une réponse valide', () {
      final json = {
        'token': 'abc123',
        'user_id': 'user_001',
        'needs_otp': false,
      };
      final model = LoginResponseModel.fromJson(json);
      expect(model.token, equals('abc123'));
      expect(model.userId, equals('user_001'));
      expect(model.needsOtp, isFalse);
    });

    test('gère les champs manquants avec des valeurs par défaut', () {
      final model = LoginResponseModel.fromJson({});
      expect(model.token, equals(''));
      expect(model.userId, equals(''));
      expect(model.needsOtp, isFalse);
    });

    test('parse needs_otp = true', () {
      final model = LoginResponseModel.fromJson({
        'token': 'tok',
        'user_id': 'u1',
        'needs_otp': true,
      });
      expect(model.needsOtp, isTrue);
    });
  });

  group('UserResponseModel.fromJson', () {
    test('parse correctement et convertit en domaine', () {
      final json = {
        'id': 'u_001',
        'phone': '771234567',
        'nom': 'Amadou Diallo',
        'registre': 'SN-123456-A',
        'date_naissance': '1990-05-15',
        'commune_id': 'DK-DK-01',
        'commune_nom': 'Dakar Plateau',
      };
      final model = UserResponseModel.fromJson(json);
      expect(model.nom, equals('Amadou Diallo'));

      final domain = model.toDomain();
      expect(domain, isA<UserModel>());
      expect(domain.nom, equals('Amadou Diallo'));
      expect(domain.communeNom, equals('Dakar Plateau'));
      expect(domain.dateNaissance, equals(DateTime(1990, 5, 15)));
    });

    test('gère une date invalide sans crash', () {
      final json = {
        'id': 'u1', 'phone': '77', 'nom': 'Test',
        'registre': 'SN', 'date_naissance': 'invalid',
        'commune_id': 'c1', 'commune_nom': 'Test',
      };
      final domain = UserResponseModel.fromJson(json).toDomain();
      expect(domain.dateNaissance, equals(DateTime(1990)));
    });
  });

  group('UserModel.copyWith', () {
    test('copie en modifiant uniquement les champs spécifiés', () {
      final user = UserModel(
        id: '1', phone: '77', nom: 'Amadou',
        registre: 'SN-1', dateNaissance: DateTime(1990),
        communeId: 'c1', communeNom: 'Dakar',
      );
      final updated = user.copyWith(nom: 'Fatou');
      expect(updated.nom, equals('Fatou'));
      expect(updated.id, equals('1')); // inchangé
      expect(updated.communeNom, equals('Dakar')); // inchangé
    });
  });
}
