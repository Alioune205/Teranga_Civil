class PaymentModel {
  final bool success;
  final String? receipt;
  final String? transactionId;

  const PaymentModel({
    required this.success,
    this.receipt,
    this.transactionId,
  });

  /// [json] est l'objet `data` déjà déballé de l'enveloppe
  /// `{success, message, data, errors}` — voir `_unwrap` dans le datasource.
  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        success: (json['status'] as String?) != 'failed',
        receipt: json['receipt'] as String?,
        transactionId: json['transaction_id'] as String?,
      );
}
