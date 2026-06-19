import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepte un numéro valide sans indicatif', () {
      expect(Validators.phone('771234567'), isNull);
    });

    test('accepte un numéro avec +221', () {
      expect(Validators.phone('+221771234567'), isNull);
    });

    test('refuse un numéro trop court', () {
      expect(Validators.phone('7712345'), isNotNull);
    });

    test('refuse un préfixe invalide', () {
      expect(Validators.phone('991234567'), isNotNull);
    });

    test('refuse une valeur vide', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(null), isNotNull);
    });
  });

  group('Validators.pin', () {
    test('accepte un PIN valide', () {
      expect(Validators.pin('248631'), isNull);
    });

    test('refuse un PIN trop court', () {
      expect(Validators.pin('1234'), isNotNull);
    });

    test('refuse un PIN trivial 123456', () {
      expect(Validators.pin('123456'), isNotNull);
    });

    test('refuse un PIN trivial 000000', () {
      expect(Validators.pin('000000'), isNotNull);
    });

    test('refuse un PIN avec des lettres', () {
      expect(Validators.pin('12345a'), isNotNull);
    });
  });

  group('Validators.pinConfirmation', () {
    test('valide quand les deux PIN correspondent', () {
      expect(Validators.pinConfirmation('248631', '248631'), isNull);
    });

    test('invalide quand les PIN ne correspondent pas', () {
      expect(Validators.pinConfirmation('248631', '987654'), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('accepte un OTP valide', () {
      expect(Validators.otp('123456'), isNull);
    });

    test('refuse un OTP incomplet', () {
      expect(Validators.otp('12345'), isNotNull);
    });

    test('refuse un OTP avec lettres', () {
      expect(Validators.otp('12345a'), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('accepte un nom valide', () {
      expect(Validators.fullName('Amadou Diallo'), isNull);
    });

    test('accepte un nom avec apostrophe', () {
      expect(Validators.fullName("N'Diaye Fatou"), isNull);
    });

    test('refuse un nom trop court', () {
      expect(Validators.fullName('Al'), isNotNull);
    });

    test('refuse un nom vide', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName(null), isNotNull);
    });

    test('refuse un nom avec chiffres', () {
      expect(Validators.fullName('Amadou123'), isNotNull);
    });
  });

  group('Validators.registreNumber', () {
    test('accepte un registre valide', () {
      expect(Validators.registreNumber('SN-123456-A'), isNull);
    });

    test('refuse un registre trop court', () {
      expect(Validators.registreNumber('AB'), isNotNull);
    });

    test('refuse une valeur vide', () {
      expect(Validators.registreNumber(''), isNotNull);
    });
  });

  group('Validators.dateNaissance', () {
    test('accepte une date valide dans le passé', () {
      expect(
        Validators.dateNaissance(DateTime(1990, 5, 15)),
        isNull,
      );
    });

    test('refuse une date dans le futur', () {
      expect(
        Validators.dateNaissance(DateTime.now().add(const Duration(days: 1))),
        isNotNull,
      );
    });

    test('refuse null', () {
      expect(Validators.dateNaissance(null), isNotNull);
    });
  });

  group('Validators.anneeMarriage', () {
    test('accepte une année valide', () {
      expect(Validators.anneeMarriage(2015), isNull);
    });

    test('refuse une année future', () {
      expect(Validators.anneeMarriage(DateTime.now().year + 1), isNotNull);
    });

    test('refuse une année avant 1900', () {
      expect(Validators.anneeMarriage(1850), isNotNull);
    });

    test('refuse null', () {
      expect(Validators.anneeMarriage(null), isNotNull);
    });
  });

  group('Validators.commune', () {
    test('accepte une commune sélectionnée', () {
      expect(Validators.commune('DK-DK-01'), isNull);
    });

    test('refuse une valeur vide', () {
      expect(Validators.commune(''), isNotNull);
      expect(Validators.commune(null), isNotNull);
    });
  });
}
