import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ruedaseguro/features/policy/data/policy_repository.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';
import 'package:ruedaseguro/features/policy/domain/policy_type_model.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';

// ─── Policy types (product selection screen) ──────────────────────

class PolicyTypesNotifier extends AsyncNotifier<List<PolicyTypeModel>> {
  @override
  Future<List<PolicyTypeModel>> build() =>
      PolicyRepository.instance.fetchActivePolicyTypes();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        PolicyRepository.instance.fetchActivePolicyTypes);
  }
}

final policyTypesProvider =
    AsyncNotifierProvider<PolicyTypesNotifier, List<PolicyTypeModel>>(
        PolicyTypesNotifier.new);

// ─── Single policy detail (policy detail screen) ──────────────────

final policyDetailProvider =
    FutureProvider.family<PolicyDetailModel?, String>((ref, policyId) {
  return PolicyRepository.instance.fetchPolicyDetail(policyId);
});

// ─── Active policy for the current user (home screen) ─────────────

final activePolicySummaryProvider =
    FutureProvider<PolicyDetailModel?>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return null;

  final policyId =
      await PolicyRepository.instance.fetchActivePolicyId(userId);
  if (policyId == null) return null;

  return PolicyRepository.instance.fetchPolicyDetail(policyId);
});
