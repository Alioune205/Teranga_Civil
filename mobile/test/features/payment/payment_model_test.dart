import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_civil/features/payment/data/models/payment_model.dart';

void main() {
  group('PaymentModel.fromJson', () {
    test('parse un paiement réussi', () {
      final json = {
        'success': true,
        'receipt': 'REC-2024-001',
        'transaction_id': 'TXN-ABC123',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.success, isTrue);
      expect(model.receipt, equals('REC-2024-001'));
      expect(model.transactionId, equals('TXN-ABC123'));
    });

    test('parse un paiement échoué', () {
      final json = {'success': false};
      final model = PaymentModel.fromJson(json);
      expect(model.success, isFalse);
      expect(model.receipt, isNull);
      expect(model.transactionId, isNull);
    });

    test('gère les champs manquants', () {
      final model = PaymentModel.fromJson({});
      expect(model.success, isFalse);
    });
  });
}
