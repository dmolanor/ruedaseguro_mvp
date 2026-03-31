// RS-060 / RS-061 — Carrier API client interface + stub implementation.
//
// When William provides Acsel/Sirway sandbox credentials:
//   1. Create AcselSirwayClient implements CarrierApiClient
//   2. Point PolicyIssuanceService._client to AcselSirwayClient
//   3. Flip the CARRIER_API_STUB dart-define to false

/// Payload sent to the carrier to register a policy.
class CarrierSubmissionPayload {
  final String policyId;
  final String riderCedula;
  final String riderIdType;  // 'V' | 'E' | 'CC'
  final String riderFullName;
  final String riderPhone;
  final String vehiclePlate;
  final String vehicleBrand;
  final String vehicleModel;
  final int vehicleYear;
  final DateTime startDate;
  final DateTime endDate;
  final double premiumUsd;
  final String productCode; // Carrier-specific code for the plan tier

  const CarrierSubmissionPayload({
    required this.policyId,
    required this.riderCedula,
    required this.riderIdType,
    required this.riderFullName,
    required this.riderPhone,
    required this.vehiclePlate,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.startDate,
    required this.endDate,
    required this.premiumUsd,
    required this.productCode,
  });
}

/// Result from the carrier API.
class CarrierApiResult {
  final bool success;
  final String? policyNumber; // Set when success == true
  final String? errorCode;
  final String? errorMessage;

  const CarrierApiResult.confirmed({required String policyNumber})
      : success = true,
        policyNumber = policyNumber,
        errorCode = null,
        errorMessage = null;

  const CarrierApiResult.failed({
    required String errorCode,
    required String errorMessage,
  })  : success = false,
        policyNumber = null,
        errorCode = errorCode,
        errorMessage = errorMessage;
}

/// Abstract interface — swap implementations without touching call sites.
abstract class CarrierApiClient {
  Future<CarrierApiResult> submitPolicy(CarrierSubmissionPayload payload);
}

/// Stub that always confirms with a generated policy number.
/// Replace with AcselSirwayClient once William provides endpoint + auth docs.
class StubCarrierClient implements CarrierApiClient {
  const StubCarrierClient();

  @override
  Future<CarrierApiResult> submitPolicy(CarrierSubmissionPayload payload) async {
    // Simulate realistic API latency
    await Future.delayed(const Duration(seconds: 2));

    // Generate a deterministic-looking fake policy number
    final ts = DateTime.now().millisecondsSinceEpoch % 10000000;
    final plate = payload.vehiclePlate.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return CarrierApiResult.confirmed(
      policyNumber: 'ACL-$plate-$ts',
    );
  }
}
