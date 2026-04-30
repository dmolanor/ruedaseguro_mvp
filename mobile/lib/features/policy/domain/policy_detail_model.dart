import 'package:intl/intl.dart';

class PolicyDetailModel {
  final String id;
  final String
  status; // 'pending_payment' | 'pending_emission' | 'active' | ...
  final String
  issuanceStatus; // 'pending' | 'provisional' | 'confirmed' | 'rejected'
  final String startDate; // 'YYYY-MM-DD'
  final String endDate; // 'YYYY-MM-DD'
  final double premiumUsd;
  final double premiumVes;
  final double exchangeRate;

  // Rider (from profiles join)
  final String riderFullName;
  final String riderIdType;
  final String riderIdNumber;

  // Vehicle (from vehicles join)
  final String vehicleBrand;
  final String vehicleModel;
  final int vehicleYear;
  final String vehiclePlate;
  final String vehicleColor;

  // Plan (from policy_types join)
  final String planName;
  final String tier; // 'basica' | 'plus' | 'ampliada'

  // Carrier (from carriers join)
  final String carrierName;

  // From carrier API (null until confirmed)
  final String? carrierPolicyNumber;

  const PolicyDetailModel({
    required this.id,
    required this.status,
    required this.issuanceStatus,
    required this.startDate,
    required this.endDate,
    required this.premiumUsd,
    required this.premiumVes,
    required this.exchangeRate,
    required this.riderFullName,
    required this.riderIdType,
    required this.riderIdNumber,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehiclePlate,
    required this.vehicleColor,
    required this.planName,
    required this.tier,
    required this.carrierName,
    this.carrierPolicyNumber,
  });

  factory PolicyDetailModel.fromMap(Map<String, dynamic> m) {
    final profile = (m['profiles'] as Map<String, dynamic>?) ?? {};
    final vehicle = (m['vehicles'] as Map<String, dynamic>?) ?? {};
    final policyType = (m['policy_types'] as Map<String, dynamic>?) ?? {};
    final carrier = (m['carriers'] as Map<String, dynamic>?) ?? {};

    return PolicyDetailModel(
      id: m['id'] as String,
      status: m['status'] as String,
      issuanceStatus: m['issuance_status'] as String,
      startDate: (m['coverage_start'] as String).substring(0, 10),
      endDate: (m['coverage_end'] as String).substring(0, 10),
      premiumUsd: (m['price_usd'] as num).toDouble(),
      premiumVes: (m['price_ves'] as num).toDouble(),
      exchangeRate: (m['exchange_rate'] as num).toDouble(),
      riderFullName:
          '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
      riderIdType: profile['id_type'] as String,
      riderIdNumber: profile['id_number'] as String,
      vehicleBrand: vehicle['brand'] as String,
      vehicleModel: vehicle['model'] as String,
      vehicleYear: vehicle['year'] as int,
      vehiclePlate: vehicle['plate'] as String,
      vehicleColor: vehicle['color'] as String? ?? '',
      planName: policyType['name'] as String,
      tier: policyType['tier'] as String,
      carrierName: carrier['name'] as String,
      carrierPolicyNumber: m['carrier_policy_number'] as String?,
    );
  }

  // ─── Derived helpers ──────────────────────────────────────────────

  /// Human-readable policy number: carrier number if confirmed, else short UUID.
  String get displayNumber =>
      carrierPolicyNumber ?? 'RS-${id.substring(0, 8).toUpperCase()}';

  bool get isProvisional => issuanceStatus == 'provisional';
  bool get isConfirmed => issuanceStatus == 'confirmed';
  bool get isActive => status == 'active';
  bool get isPendingEmission => status == 'pending_emission';

  String get formattedStartDate => _formatDate(startDate);
  String get formattedEndDate => _formatDate(endDate);

  int get daysRemaining {
    final end = DateTime.tryParse(endDate);
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays.clamp(0, 366);
  }

  double get progressFraction => daysRemaining / 365.0;

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy', 'es').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
