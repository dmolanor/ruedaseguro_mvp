import 'package:uuid/uuid.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';
import 'package:ruedaseguro/features/policy/domain/policy_type_model.dart';

class PolicyRepository {
  PolicyRepository._();
  static final instance = PolicyRepository._();

  final _uuid = const Uuid();

  /// Returns active policy types for Seguros Pirámide by default.
  /// Falls back to the first active carrier if no specific carrier is provided.
  Future<List<PolicyTypeModel>> fetchActivePolicyTypes() async {
    final rows = await SupabaseService.client
        .from(SupabaseConstants.policyTypes)
        .select('*, carriers!carrier_id(name)')
        .eq('is_active', true)
        .order('price_usd', ascending: true);

    return (rows as List)
        .map((r) => PolicyTypeModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Creates a provisional policy record.
  /// Returns the new policy UUID. Idempotent: reuses any existing
  /// pending_emission record for the same profile+vehicle instead of
  /// creating a duplicate on retry or double-tap.
  Future<String> createPolicyRecord({
    required String profileId,
    required String vehicleId,
    required String carrierId,
    required String policyTypeId,
    required double priceUsd,
    required double priceVes,
    required double exchangeRate,
  }) async {
    final existing = await SupabaseService.client
        .from(SupabaseConstants.policies)
        .select('id')
        .eq('profile_id', profileId)
        .eq('vehicle_id', vehicleId)
        .eq('status', 'pending_emission')
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final policyId = _uuid.v4();
    final now = DateTime.now().toUtc();

    await SupabaseService.client.from(SupabaseConstants.policies).insert({
      'id': policyId,
      'policy_number':
          'RS-${now.year}-${policyId.substring(0, 8).toUpperCase()}',
      'profile_id': profileId,
      'vehicle_id': vehicleId,
      'carrier_id': carrierId,
      'policy_type_id': policyTypeId,
      'status': 'pending_emission',
      'issuance_status': 'provisional',
      'coverage_start': now.toIso8601String(),
      'coverage_end': now.add(const Duration(days: 365)).toIso8601String(),
      'price_usd': priceUsd,
      'price_ves': priceVes,
      'exchange_rate': exchangeRate,
      'rate_timestamp': now.toIso8601String(),
    });

    return policyId;
  }

  /// Fetches the rider's active policy ID (most recent pending_emission or active).
  Future<String?> fetchActivePolicyId(String profileId) async {
    final row = await SupabaseService.client
        .from(SupabaseConstants.policies)
        .select('id')
        .eq('profile_id', profileId)
        .inFilter('status', ['active', 'pending_emission'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// Looks up the vehicle ID for the current user.
  Future<String?> fetchVehicleId(String userId) async {
    final row = await SupabaseService.client
        .from(SupabaseConstants.vehicles)
        .select('id')
        .eq('owner_id', userId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// Fetches the plate string for a known vehicle UUID.
  Future<String?> fetchVehiclePlate(String vehicleId) async {
    final row = await SupabaseService.client
        .from(SupabaseConstants.vehicles)
        .select('plate')
        .eq('id', vehicleId)
        .maybeSingle();
    return row?['plate'] as String?;
  }

  /// Fetches full policy detail with joins on profiles, vehicles,
  /// policy_types and carriers. Returns null if the policy doesn't exist.
  Future<PolicyDetailModel?> fetchPolicyDetail(String policyId) async {
    final row = await SupabaseService.client
        .from(SupabaseConstants.policies)
        .select(
          '*,'
          'profiles!profile_id(first_name,last_name,id_type,id_number),'
          'vehicles!vehicle_id(brand,model,year,plate,color),'
          'policy_types!policy_type_id(name,tier),'
          'carriers!carrier_id(name)',
        )
        .eq('id', policyId)
        .maybeSingle();

    if (row == null) return null;
    return PolicyDetailModel.fromMap(row as Map<String, dynamic>);
  }
}
