import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ruedaseguro/features/claims/data/claim_repository.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';

final userClaimsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  return ClaimRepository.instance.fetchClaims(userId);
});
