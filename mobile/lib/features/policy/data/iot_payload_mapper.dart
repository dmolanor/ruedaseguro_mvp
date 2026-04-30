// RS-094 — IotPayloadMapper
//
// Normalises RuedaSeguro's internal data models into Quasar Infotech's
// expected API format. All transformations are documented inline.

import 'package:ruedaseguro/features/policy/data/iot_api_client.dart';

class IotPayloadMapper {
  IotPayloadMapper._();

  // ── Plan tier mapping ────────────────────────────────────────────────────────
  // RuedaSeguro internal tier → IoT platform plan_tier code.
  // Pending confirmation from Thony for 'ampliada'.
  static const _planTierMap = {
    'rcv_basico': 'basic',
    'rcv_accidentes': 'comprehensive_plus',
    'rcv_ampliada': 'premium',
    // Legacy keys
    'basica': 'basic',
    'plus': 'comprehensive_plus',
    'ampliada': 'premium',
  };

  /// Maps our internal plan tier to the IoT platform code.
  /// Defaults to 'basic' if the tier is unknown.
  static String mapPlanTier(String? tier) =>
      _planTierMap[tier?.toLowerCase()] ?? 'basic';

  // ── Plate normalisation ───────────────────────────────────────────────────────
  /// Removes dashes and spaces from a Venezuelan plate.
  /// "AB-123-CD" → "AB123CD"
  static String normalisePlate(String plate) =>
      plate.replaceAll(RegExp(r'[-\s]'), '').toUpperCase();

  // ── Payment method mapping ────────────────────────────────────────────────────
  static const _methodMap = {
    'pago_movil_p2p': 'pago_movil',
    'bank_transfer': 'transferencia',
    'debito_inmediato': 'debito_inmediato',
  };

  static String mapPaymentMethod(String? method) =>
      _methodMap[method] ?? method ?? 'pago_movil';

  // ── National ID formatting ────────────────────────────────────────────────────
  /// Formats as "V-12345678" expected by the IoT platform.
  static String formatNationalId(String? type, String? number) {
    final t = (type ?? 'V').toUpperCase();
    final n = (number ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return '$t-$n';
  }

  // ── Date formatting ───────────────────────────────────────────────────────────
  static String formatDate(DateTime? date) => date != null
      ? '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}'
      : '';

  // ── Phone to E.164 ────────────────────────────────────────────────────────────
  /// Converts Venezuelan phone "0414-1234567" → "+584141234567".
  static String toE164Venezuela(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('58')) return '+$digits';
    if (digits.startsWith('0')) return '+58${digits.substring(1)}';
    return '+58$digits';
  }

  // ── Full mapper ───────────────────────────────────────────────────────────────
  static IotRiderData buildRiderData({
    required String? firstName,
    required String? lastName,
    required String? idType,
    required String? idNumber,
    required DateTime? dob,
    required String? email,
    required String? phone,
    String? kycDocumentId,
  }) => IotRiderData(
    firstName: firstName ?? '',
    lastName: lastName ?? '',
    nationalId: formatNationalId(idType, idNumber),
    dob: formatDate(dob),
    email: email ?? '',
    phone: toE164Venezuela(phone),
    kycDocumentId: kycDocumentId,
  );

  static IotAssetData buildAssetData({
    required String? plate,
    required String? brand,
    required String? model,
    required int? year,
    required String? serialNiv,
  }) => IotAssetData(
    vehicleType: 'motorbike',
    make: brand ?? '',
    model: model ?? '',
    year: year ?? DateTime.now().year,
    vin: serialNiv ?? '',
    licensePlate: normalisePlate(plate ?? ''),
  );

  static IotCoverageData buildCoverageData({
    required String? planTier,
    required double premiumAmount,
  }) => IotCoverageData(
    planTier: mapPlanTier(planTier),
    premiumAmount: premiumAmount,
  );

  static IotPaymentData buildPaymentData({
    required String? method,
    required String? bankCode,
    required String? sourcePhone,
    required String? reference,
    required DateTime? paymentDate,
  }) => IotPaymentData(
    method: mapPaymentMethod(method),
    bankCode: bankCode ?? '',
    sourcePhone: toE164Venezuela(sourcePhone),
    paymentReference: reference ?? '',
    paymentDate: formatDate(paymentDate ?? DateTime.now()),
  );
}
