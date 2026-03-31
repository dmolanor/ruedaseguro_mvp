// RS-061 — Policy issuance state machine.
//
// State transitions (per section 9.1 of MVP_PLAN_v3.md):
//   provisional → api_submitted → confirmed   (carrier API succeeded)
//                              → provisional  (failed, retry queue handles retries)

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/features/audit/data/audit_repository.dart';
import 'package:ruedaseguro/features/policy/data/carrier_api_client.dart';

enum IssuanceOutcome { confirmed, provisional }

class IssuanceResult {
  final IssuanceOutcome outcome;
  final String? carrierPolicyNumber;
  final String? errorMessage;

  const IssuanceResult._({
    required this.outcome,
    this.carrierPolicyNumber,
    this.errorMessage,
  });

  factory IssuanceResult.confirmed({required String policyNumber}) =>
      IssuanceResult._(
          outcome: IssuanceOutcome.confirmed, carrierPolicyNumber: policyNumber);

  factory IssuanceResult.provisional({String? reason}) =>
      IssuanceResult._(outcome: IssuanceOutcome.provisional, errorMessage: reason);

  bool get isConfirmed => outcome == IssuanceOutcome.confirmed;
}

class PolicyIssuanceService {
  PolicyIssuanceService._();
  static final instance = PolicyIssuanceService._();

  // Swap to AcselSirwayClient once William provides credentials (RS-060).
  final CarrierApiClient _client = const StubCarrierClient();

  /// Attempt to register [policyId] with the carrier API.
  ///
  /// On success:  issuance_status → 'confirmed', policy.status → 'active'.
  /// On failure:  issuance_status → 'provisional'; retry queue re-attempts
  ///              every 15 min up to 3 times (via policy-retry Edge Function).
  Future<IssuanceResult> attemptIssuance({
    required String policyId,
    required String profileId,
    required CarrierSubmissionPayload payload,
  }) async {
    // 1. Read current attempt count, then mark api_submitted
    int attempts = 0;
    try {
      final row = await SupabaseService.client
          .from(SupabaseConstants.policies)
          .select('carrier_api_attempts')
          .eq('id', policyId)
          .maybeSingle();
      attempts = (row?['carrier_api_attempts'] as int? ?? 0) + 1;

      await SupabaseService.client.from(SupabaseConstants.policies).update({
        'issuance_status': 'api_submitted',
        'carrier_api_attempts': attempts,
      }).eq('id', policyId);
    } catch (_) {
      // Non-fatal — proceed with issuance attempt regardless
    }

    // 2. Call carrier API (10 s hard timeout)
    try {
      final result = await _client
          .submitPolicy(payload)
          .timeout(const Duration(seconds: 10));

      final now = DateTime.now().toUtc().toIso8601String();

      if (result.success && result.policyNumber != null) {
        // 3a. Confirmed — flip to active
        await SupabaseService.client
            .from(SupabaseConstants.policies)
            .update({
              'issuance_status': 'confirmed',
              'carrier_policy_number': result.policyNumber,
              'confirmed_at': now,
              'status': 'active',
            })
            .eq('id', policyId);

        await AuditRepository.instance.logEvent(
          actorId: profileId,
          eventType: 'policy.carrier_confirmed',
          targetId: policyId,
          targetTable: 'policies',
          payload: {'carrier_policy_number': result.policyNumber},
        );

        return IssuanceResult.confirmed(policyNumber: result.policyNumber!);
      }

      // 3b. Carrier returned explicit error
      await _setProvisional(policyId, profileId, now,
          reason: result.errorMessage ?? 'carrier_rejected');
      return IssuanceResult.provisional(reason: result.errorMessage);
    } catch (e) {
      // Timeout or network error
      final now = DateTime.now().toUtc().toIso8601String();
      await _setProvisional(policyId, profileId, now, reason: 'timeout_or_network');
      return IssuanceResult.provisional(reason: 'API sin respuesta');
    }
  }

  Future<void> _setProvisional(
    String policyId,
    String profileId,
    String now, {
    required String reason,
  }) async {
    try {
      await SupabaseService.client
          .from(SupabaseConstants.policies)
          .update({
            'issuance_status': 'provisional',
            'provisional_issued_at': now,
          })
          .eq('id', policyId);

      await AuditRepository.instance.logEvent(
        actorId: profileId,
        eventType: 'policy.carrier_provisional',
        targetId: policyId,
        targetTable: 'policies',
        payload: {'reason': reason},
      );
    } catch (_) {
      // Best-effort — policy already has provisional issuance_status from creation
    }
  }
}
