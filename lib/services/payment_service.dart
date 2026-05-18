import '../core/network/api_client.dart';

class PaymentService {
  PaymentService(this._client);

  final ApiClient _client;

  Future<PaymentSession> startPayment(String bookingId) async {
    final res = await _client.dio.post('/payments', data: {'bookingId': bookingId});
    final data = res.data['data'] as Map<String, dynamic>;
    final payment = data['payment'] as Map<String, dynamic>;

    return PaymentSession(
      paymentId: payment['_id']?.toString() ?? '',
      paymentIntentId: data['paymentIntentId']?.toString(),
      checkoutUrl: data['checkoutUrl']?.toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? (payment['amount'] as num?)?.toDouble() ?? 0,
      isTestMode: data['isTestMode'] == true,
      linkError: data['linkError']?.toString(),
    );
  }

  Future<void> confirmPayment(String paymentId, {bool testConfirm = false}) async {
    await _client.dio.post(
      '/payments/$paymentId/confirm',
      data: {if (testConfirm) 'testConfirm': true},
    );
  }
}

class PaymentSession {
  const PaymentSession({
    required this.paymentId,
    required this.amount,
    this.checkoutUrl,
    this.paymentIntentId,
    this.isTestMode = false,
    this.linkError,
  });

  final String paymentId;
  final double amount;
  final String? checkoutUrl;
  final String? paymentIntentId;
  final bool isTestMode;
  final String? linkError;

  bool get hasCheckoutUrl => checkoutUrl != null && checkoutUrl!.isNotEmpty;
}
