import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('RegistrationData', () {
    test('isStep1Valid est false si champs manquants', () {
      const data = RegistrationData();
      expect(data.isStep1Valid, isFalse);
    });

    test('isStep1Valid est true si tous les champs sont remplis', () {
      final data = RegistrationData(
        nom: 'Amadou Diallo',
        registre: 'SN-123456-A',
        dateNaissance: DateTime(1990, 5, 15),
        phone: '771234567',
      );
      expect(data.isStep1Valid, isTrue);
    });

    test('isStep2Valid est false si commune non sélectionnée', () {
      const data = RegistrationData();
      expect(data.isStep2Valid, isFalse);
    });

    test('isStep2Valid est true si communeId renseigné', () {
      const data = RegistrationData(communeId: 'DK-DK-01');
      expect(data.isStep2Valid, isTrue);
    });

    test('copyWith préserve les valeurs non modifiées', () {
      const data = RegistrationData(nom: 'Amadou', phone: '771234567');
      final updated = data.copyWith(nom: 'Fatou');
      expect(updated.nom, equals('Fatou'));
      expect(updated.phone, equals('771234567'));
    });

    test('toMap retourne les bonnes clés', () {
      const data = RegistrationData(
        nom: 'Amadou', registre: 'SN-1', phone: '77',
        communeId: 'c1', communeNom: 'Dakar',
      );
      final map = data.toMap();
      expect(map.containsKey('nom'), isTrue);
      expect(map.containsKey('phone'), isTrue);
      expect(map.containsKey('communeId'), isTrue);
    });
  });
}
