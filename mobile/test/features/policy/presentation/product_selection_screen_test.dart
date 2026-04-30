import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/features/policy/domain/policy_type_model.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/product_selection_screen.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/providers/bcv_rate_provider.dart';

// ─── Fixture helpers ──────────────────────────────────────────────

const kFakeBcvRate = BcvRate(
  rate: 80.0,
  fetchedAt: '2026-03-29T10:00:00Z',
  source: 'test',
  stale: false,
  isSuspicious: false,
);

PolicyTypeModel fakePolicyType(InsurancePlan plan) {
  return PolicyTypeModel(
    id: plan.id,
    carrierId: '11111111-1111-1111-1111-111111111111',
    code: plan.tier,
    name: plan.name,
    tier: plan.tier,
    priceUsd: plan.priceUsd,
    coverageAmountUsd: 5000,
    durationDays: 365,
    paymentFrequency: 'annual',
    coverageDetails: const {},
    isRecommended: plan.isRecommended,
    targetPercentage: 0.4,
    isActive: true,
  );
}

GoRouter _router(Widget child) => GoRouter(
  initialLocation: '/test',
  routes: [
    GoRoute(path: '/test', builder: (_, __) => child),
    GoRoute(
      path: '/policy/quote',
      builder: (_, __) => const Scaffold(body: Center(child: Text('QUOTE'))),
    ),
  ],
);

// ─── Fake notifiers (extend real notifier to satisfy Riverpod 3.x) ──

class AlwaysLoadingPolicyTypes extends PolicyTypesNotifier {
  @override
  Future<List<PolicyTypeModel>> build() =>
      Completer<List<PolicyTypeModel>>().future; // never completes, no pending timer
}

class FixedPolicyTypes extends PolicyTypesNotifier {
  FixedPolicyTypes(this.data);
  final List<PolicyTypeModel> data;

  @override
  Future<List<PolicyTypeModel>> build() async => data;
}

class ErrorPolicyTypes extends PolicyTypesNotifier {
  @override
  Future<List<PolicyTypeModel>> build() => Future.error(Exception('offline'));
}

class FixedBcvRate extends BcvRateNotifier {
  FixedBcvRate(this.rate);
  final BcvRate rate;

  @override
  Future<BcvRate> build() async => rate;
}

class DemoAuth extends AuthNotifier {
  @override
  RSAuthState build() =>
      const RSAuthState(status: AuthStatus.authenticatedWithProfile);
}

// ─── Tests ───────────────────────────────────────────────────────

void main() {
  group('ProductSelectionScreen', () {
    testWidgets('shows shimmer while policy types are loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyTypesProvider.overrideWith(AlwaysLoadingPolicyTypes.new),
            bcvRateProvider.overrideWith(() => FixedBcvRate(kFakeBcvRate)),
            authProvider.overrideWith(DemoAuth.new),
          ],
          child: MaterialApp.router(
            routerConfig: _router(const ProductSelectionScreen()),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('shows plan cards when policy types are loaded', (
      tester,
    ) async {
      // Tall viewport so all 3 plan cards are rendered by the ListView.
      await tester.binding.setSurfaceSize(const Size(411, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final plans = MockPlans.all.map(fakePolicyType).toList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyTypesProvider.overrideWith(() => FixedPolicyTypes(plans)),
            bcvRateProvider.overrideWith(() => FixedBcvRate(kFakeBcvRate)),
            authProvider.overrideWith(DemoAuth.new),
          ],
          child: MaterialApp.router(
            routerConfig: _router(const ProductSelectionScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('RCV Básica'), findsOneWidget);
      expect(find.text('RCV Plus'), findsOneWidget);
      expect(find.text('Cobertura Ampliada'), findsOneWidget);
    });

    testWidgets('falls back to mock plans on provider error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyTypesProvider.overrideWith(ErrorPolicyTypes.new),
            bcvRateProvider.overrideWith(() => FixedBcvRate(kFakeBcvRate)),
            authProvider.overrideWith(DemoAuth.new),
          ],
          child: MaterialApp.router(
            routerConfig: _router(const ProductSelectionScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(MockPlans.all.first.name), findsOneWidget);
    });

    testWidgets('shows live BCV rate label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyTypesProvider.overrideWith(() => FixedPolicyTypes([])),
            bcvRateProvider.overrideWith(() => FixedBcvRate(kFakeBcvRate)),
            authProvider.overrideWith(DemoAuth.new),
          ],
          child: MaterialApp.router(
            routerConfig: _router(const ProductSelectionScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('1 USD = 80.00 VES'), findsOneWidget);
    });
  });
}
