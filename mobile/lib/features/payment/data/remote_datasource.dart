import '../../../core/network/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/payment_model.dart';

class PaymentRemoteDatasource {
  final DioClient client;
  const PaymentRemoteDatasource({required this.client});

  Future<PaymentModel> initiatePayment({
    required String dossierId,
    required String method,
    required String phone,
  }) async {
    final res = await client.post('/initiate/', data: {
      'dossier_id': dossierId,
      'method': method,
      'phone': phone,
    });
    if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null) {
      final body = res.data as Map<String, dynamic>;
      // L'API renvoie l'enveloppe {success, message, data, errors} :
      // on déballe `data` pour récupérer status/transaction_id.
      final payload = (body['data'] as Map<String, dynamic>?) ?? body;
      return PaymentModel.fromJson(payload);
    }
    final body = res.data;
    String message = 'Le paiement a échoué. Vérifiez votre solde.';
    if (body is Map<String, dynamic> && body['message'] is String) {
      message = body['message'] as String;
    }
    throw ApiException(
      message: message,
      statusCode: res.statusCode,
    );
  }
}
