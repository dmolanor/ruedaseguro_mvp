import 'package:uuid/uuid.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';

class PaymentRepository {
  PaymentRepository._();
  static final instance = PaymentRepository._();

  final _uuid = const Uuid();

  /// Creates a payment record with status='pending'.
  /// Returns the new payment UUID.
  Future<String> createPaymentRecord({
    required String policyId,
    required String profileId,
    required double amountUsd,
    required double amountVes,
    required double exchangeRate,
    required String method, // 'pago_movil_p2p' | 'bank_transfer'
    String? pagoMovilReference,
    String? pagoMovilBankCode,
    String? receiptUrl,
  }) async {
    final paymentId = _uuid.v4();
    final idempotencyKey = _uuid.v4();

    await SupabaseService.client.from(SupabaseConstants.payments).insert({
      'id': paymentId,
      'policy_id': policyId,
      'profile_id': profileId,
      'idempotency_key': idempotencyKey,
      'amount_usd': amountUsd,
      'amount_ves': amountVes,
      'exchange_rate': exchangeRate,
      'rate_timestamp': DateTime.now().toUtc().toIso8601String(),
      'method': method,
      if (pagoMovilReference != null) 'reference': pagoMovilReference,
      if (pagoMovilBankCode != null) 'bank_code': pagoMovilBankCode,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      'status': 'pending',
    });

    return paymentId;
  }
}
