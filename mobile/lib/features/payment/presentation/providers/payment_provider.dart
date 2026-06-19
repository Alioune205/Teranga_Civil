import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/remote_datasource.dart';

class PaymentState {
  final bool isLoading;
  final String? error;
  final bool success;
  final String? transactionId;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.transactionId,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    String? transactionId,
    bool clearError = false,
  }) =>
      PaymentState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        success: success ?? this.success,
        transactionId: transactionId ?? this.transactionId,
      );
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRemoteDatasource _ds;
  PaymentNotifier(this._ds) : super(const PaymentState());

  Future<void> pay({
    required String dossierId,
    required String method,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _ds.initiatePayment(
        dossierId: dossierId,
        method: method,
        phone: phone,
      );
      state = state.copyWith(
        isLoading: false,
        success: result.success,
        transactionId: result.transactionId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void reset() => state = const PaymentState();
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) =>
        PaymentNotifier(
          PaymentRemoteDatasource(client: ref.read(dioClientProvider)),
        ));
