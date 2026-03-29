import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';

class BcvRate {
  const BcvRate({
    required this.rate,
    required this.fetchedAt,
    required this.source,
    required this.stale,
    required this.isSuspicious,
  });

  final double rate;
  final String fetchedAt;
  final String source;
  final bool stale;
  final bool isSuspicious;

  factory BcvRate.fromMap(Map<String, dynamic> map) {
    return BcvRate(
      rate: (map['rate'] as num).toDouble(),
      fetchedAt: map['fetched_at'] as String,
      source: map['source'] as String? ?? 'unknown',
      stale: map['stale'] as bool? ?? false,
      isSuspicious: map['is_suspicious'] as bool? ?? false,
    );
  }

  double toVes(double usd) => usd * rate;

  /// Fallback when the edge function is unavailable.
  static const fallback = BcvRate(
    rate: 78.50,
    fetchedAt: '',
    source: 'fallback',
    stale: true,
    isSuspicious: false,
  );
}

class BcvRateNotifier extends AsyncNotifier<BcvRate> {
  @override
  Future<BcvRate> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<BcvRate> _fetch() async {
    try {
      final res = await SupabaseService.functions
          .invoke(SupabaseConstants.fnBcvRate);
      if (res.status != null && res.status! >= 400) {
        return BcvRate.fallback;
      }
      final data = res.data as Map<String, dynamic>;
      return BcvRate.fromMap(data);
    } catch (_) {
      return BcvRate.fallback;
    }
  }
}

final bcvRateProvider =
    AsyncNotifierProvider<BcvRateNotifier, BcvRate>(BcvRateNotifier.new);
