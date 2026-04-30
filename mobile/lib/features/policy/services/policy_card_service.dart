import 'dart:convert';

/// RS-101: Generates the data encoded in the QR carnet.
///
/// The QR encodes a compact JSON payload that the verify-policy Edge Function
/// (or any offline reader) can decode to confirm basic policy validity.
class PolicyCardService {
  PolicyCardService._();
  static final instance = PolicyCardService._();

  /// Returns the JSON string to embed in the QR code.
  String generateQrData({
    required String policyId,
    required String policyNumber,
    required String plate,
    required String holderName,
    required String tier,
    required String expiryIso,
  }) {
    return jsonEncode({
      'id': policyId,
      'num': policyNumber,
      'plate': plate,
      'holder': holderName,
      'tier': tier,
      'exp': expiryIso,
    });
  }

  /// Returns the text shown on the carnet badge row.
  static String tierLabel(String tier) {
    switch (tier) {
      case 'basica':
        return 'RCV Básica';
      case 'plus':
        return 'RCV Plus';
      case 'ampliada':
        return 'Cobertura Ampliada';
      default:
        return tier;
    }
  }
}
