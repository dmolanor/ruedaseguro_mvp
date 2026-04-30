// RS-093 — IotApiClient: abstract interface + StubIotClient for Quasar Infotech
// (Thony's IoT platform).
//
// Real implementation (QuasarInfotechClient) is blocked pending:
//   • kyc_document_id endpoint clarification
//   • Full plan_tier mapping confirmation
//   • Device pairing flow details
// Create QuasarInfotechClient once Thony provides the above.

// ─── Request models ───────────────────────────────────────────────────────────

class IotRiderData {
  const IotRiderData({
    required this.firstName,
    required this.lastName,
    required this.nationalId, // e.g. "V-12345678"
    required this.dob, // "YYYY-MM-DD"
    required this.email,
    required this.phone, // E.164
    this.kycDocumentId, // from KYC upload step — pending Thony
  });

  final String firstName;
  final String lastName;
  final String nationalId;
  final String dob;
  final String email;
  final String phone;
  final String? kycDocumentId;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'national_id': nationalId,
    'dob': dob,
    'email': email,
    'phone': phone,
    if (kycDocumentId != null) 'kyc_document_id': kycDocumentId,
  };
}

class IotAssetData {
  const IotAssetData({
    required this.vehicleType, // always "motorbike" for our flow
    required this.make,
    required this.model,
    required this.year,
    required this.vin, // Serial NIV
    required this.licensePlate, // NO dashes (normalised)
  });

  final String vehicleType;
  final String make;
  final String model;
  final int year;
  final String vin;
  final String licensePlate;

  Map<String, dynamic> toJson() => {
    'vehicle_type': vehicleType,
    'make': make,
    'model': model,
    'year': year,
    'vin': vin,
    'license_plate': licensePlate,
  };
}

class IotCoverageData {
  const IotCoverageData({
    required this.planTier, // e.g. "basic" | "comprehensive_plus" | "premium"
    required this.premiumAmount,
    this.currency = 'USD',
  });

  final String planTier;
  final double premiumAmount;
  final String currency;

  Map<String, dynamic> toJson() => {
    'plan_tier': planTier,
    'premium_amount': premiumAmount,
    'currency': currency,
  };
}

class IotPaymentData {
  const IotPaymentData({
    required this.method, // e.g. "pago_movil"
    required this.bankCode, // 4-digit code
    required this.sourcePhone, // E.164
    required this.paymentReference,
    required this.paymentDate, // "YYYY-MM-DD"
  });

  final String method;
  final String bankCode;
  final String sourcePhone;
  final String paymentReference;
  final String paymentDate;

  Map<String, dynamic> toJson() => {
    'method': method,
    'bank_code': bankCode,
    'source_phone': sourcePhone,
    'payment_reference': paymentReference,
    'payment_date': paymentDate,
  };
}

class IotPolicyRequest {
  IotPolicyRequest({
    required this.riderData,
    required this.assetData,
    required this.selectedCoverage,
    required this.paymentData,
  }) : requestId = 'req_${DateTime.now().millisecondsSinceEpoch}',
       timestamp = DateTime.now().toUtc().toIso8601String();

  final String requestId;
  final String timestamp;
  final IotRiderData riderData;
  final IotAssetData assetData;
  final IotCoverageData selectedCoverage;
  final IotPaymentData paymentData;

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'timestamp': timestamp,
    'action': 'issue_policy',
    'rider_data': riderData.toJson(),
    'asset_data': assetData.toJson(),
    'selected_coverage': selectedCoverage.toJson(),
    'payment_data': paymentData.toJson(),
  };
}

// ─── Response models ──────────────────────────────────────────────────────────

class IotPolicyResponse {
  const IotPolicyResponse({
    required this.isSuccess,
    this.policyNumber,
    this.digitalCardUrl,
    this.fullPdfUrl,
    this.receiptUrl,
    this.transactionId,
    this.pairingCode,
    this.coverageSummary,
    this.errorMessage,
  });

  final bool isSuccess;
  final String? policyNumber; // → policies.carrier_policy_number
  final String? digitalCardUrl; // → policies.iot_card_url
  final String? fullPdfUrl; // → policies.iot_pdf_url
  final String? receiptUrl;
  final String? transactionId; // → policies.iot_transaction_id
  final String? pairingCode; // → policies.iot_pairing_code
  final List<String>? coverageSummary;
  final String? errorMessage;

  factory IotPolicyResponse.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'success') {
      return IotPolicyResponse(
        isSuccess: false,
        errorMessage: json['message']?.toString() ?? 'Error desconocido',
      );
    }
    final policy = json['policy_data'] as Map<String, dynamic>? ?? {};
    final docs = json['policy_documents'] as Map<String, dynamic>? ?? {};
    final receipt = json['financial_receipt'] as Map<String, dynamic>? ?? {};
    final telemetry = json['telemetry_setup'] as Map<String, dynamic>? ?? {};
    final dynamicContent =
        docs['dynamic_content'] as Map<String, dynamic>? ?? {};
    final summary = dynamicContent['coverage_summary'];

    return IotPolicyResponse(
      isSuccess: true,
      policyNumber: policy['policy_number'] as String?,
      digitalCardUrl: docs['digital_id_card_url'] as String?,
      fullPdfUrl: docs['full_policy_pdf_url'] as String?,
      receiptUrl: receipt['receipt_url'] as String?,
      transactionId: receipt['transaction_id'] as String?,
      pairingCode: telemetry['pairing_code'] as String?,
      coverageSummary: summary is List
          ? List<String>.from(summary.map((e) => e.toString()))
          : null,
    );
  }
}

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class IotApiClient {
  Future<IotPolicyResponse> issuePolicy(IotPolicyRequest request);
}

// ─── Stub implementation ──────────────────────────────────────────────────────

/// Always returns a successful response with mock data.
/// Replace with QuasarInfotechClient once Thony provides kyc_document_id flow.
class StubIotClient implements IotApiClient {
  const StubIotClient();

  @override
  Future<IotPolicyResponse> issuePolicy(IotPolicyRequest request) async {
    await Future.delayed(const Duration(seconds: 2));
    final ts = DateTime.now().millisecondsSinceEpoch % 10000000;
    final plate = request.assetData.licensePlate;
    return IotPolicyResponse(
      isSuccess: true,
      policyNumber: 'QIT-MB-2026-$ts',
      digitalCardUrl: null, // Thony not integrated yet
      fullPdfUrl: null, // Thony not integrated yet
      transactionId: 'txn_pm_$ts',
      pairingCode: '${(1000 + ts % 9000)}-AX',
      coverageSummary: [
        'Responsabilidad Civil Vehículo (RCV)',
        'Asistencia en carretera 24/7',
        'Accidentes personales — conductor',
      ],
    );
  }
}
