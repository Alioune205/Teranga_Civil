import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/core/utils/formatters.dart';

void main() {
  group('AppFormatters.amountFCFA', () {
    test('formate 500 FCFA correctement', () {
      final result = AppFormatters.amountFCFA(500);
      expect(result, contains('500'));
      expect(result, contains('FCFA'));
    });

    test('formate 1000 FCFA avec espace', () {
      final result = AppFormatters.amountFCFA(1000);
      expect(result, contains('1'));
      expect(result, contains('000'));
      expect(result, contains('FCFA'));
    });
  });

  group('AppFormatters.phoneNumber', () {
    test('formate un numéro 9 chiffres sans indicatif', () {
      final result = AppFormatters.phoneNumber('771234567');
      expect(result, equals('+221 77 123 45 67'));
    });

    test('formate un numéro avec +221', () {
      final result = AppFormatters.phoneNumber('+221771234567');
      expect(result, contains('+221'));
    });
  });

  group('AppFormatters.initials', () {
    test('retourne deux initiales pour un nom complet', () {
      expect(AppFormatters.initials('Amadou Diallo'), equals('AD'));
    });

    test('retourne deux lettres pour un nom unique', () {
      final result = AppFormatters.initials('Fatou');
      expect(result.length, equals(2));
    });

    test('gère un nom avec plusieurs mots', () {
      expect(AppFormatters.initials('Moussa Ba Diop'), equals('MD'));
    });
  });

  group('AppFormatters.titleCase', () {
    test('capitalise correctement', () {
      expect(AppFormatters.titleCase('amadou diallo'), equals('Amadou Diallo'));
    });

    test('gère un mot unique', () {
      expect(AppFormatters.titleCase('dakar'), equals('Dakar'));
    });
  });

  group('AppFormatters.statusLabel', () {
    test('retourne le bon libellé pour chaque statut', () {
      expect(AppFormatters.statusLabel('soumis'), equals('Soumis'));
      expect(AppFormatters.statusLabel('en_verification'), equals('En vérification'));
      expect(AppFormatters.statusLabel('valide'), equals('Validé'));
      expect(AppFormatters.statusLabel('pret'), equals('Prêt'));
      expect(AppFormatters.statusLabel('rejete'), equals('Rejeté'));
      expect(AppFormatters.statusLabel('en_cours'), equals('En cours'));
    });
  });

  group('AppFormatters.certTypeLabel', () {
    test('retourne le bon libellé pour chaque type', () {
      expect(AppFormatters.certTypeLabel('naissance'),
          equals('Certificat de naissance'));
      expect(AppFormatters.certTypeLabel('deces'),
          equals('Certificat de décès'));
      expect(AppFormatters.certTypeLabel('mariage'),
          equals('Certificat de mariage'));
    });
  });

  group('AppFormatters.truncate', () {
    test('ne tronque pas si texte assez court', () {
      expect(AppFormatters.truncate('Bonjour', 20), equals('Bonjour'));
    });

    test('tronque et ajoute ... si trop long', () {
      final result = AppFormatters.truncate('Texte très long qui dépasse', 10);
      expect(result.length, equals(10));
      expect(result, endsWith('...'));
    });
  });

  group('AppFormatters.timeAgo', () {
    test("retourne à l'instant pour moins d'une minute", () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(AppFormatters.timeAgo(now), equals("à l'instant"));
    });

    test('retourne hier pour une date hier', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppFormatters.timeAgo(yesterday), equals('hier'));
    });
  });
}
