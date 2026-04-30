import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/plan_selection_screen.dart';

import 'helpers/test_helpers.dart';

/// Sets a tall viewport so all 3 plan cards are visible without scrolling.
Future<void> _setTallViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(411, 2400));
}

void main() {
  group('PlanSelectionScreen', () {
    testWidgets('renders header text', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const PlanSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Protege tu moto'), findsOneWidget);
      expect(
        find.text('Elige el plan que mejor se adapte a ti.'),
        findsOneWidget,
      );
    });

    testWidgets('renders all three plan names', (tester) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const PlanSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('RCV Básica'), findsOneWidget);
      expect(find.text('RCV Plus'), findsOneWidget);
      expect(find.text('Cobertura Ampliada'), findsOneWidget);
    });

    testWidgets('renders Elegir button for each plan', (tester) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const PlanSelectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Elegir Básica'), findsOneWidget);
      expect(find.text('Elegir Plus'), findsOneWidget);
      expect(find.text('Elegir Ampliada'), findsOneWidget);
    });

    testWidgets('tapping Elegir Básica navigates to /onboarding/cedula', (
      tester,
    ) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const PlanSelectionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elegir Básica'));
      await tester.pumpAndSettle();

      expect(find.text('NAVIGATED_TO_cedula'), findsOneWidget);
    });

    testWidgets('tapping Elegir Plus navigates to /onboarding/cedula', (
      tester,
    ) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const PlanSelectionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elegir Plus'));
      await tester.pumpAndSettle();

      expect(find.text('NAVIGATED_TO_cedula'), findsOneWidget);
    });

    testWidgets('tapping Elegir Ampliada navigates to /onboarding/cedula', (
      tester,
    ) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestableWidget(const PlanSelectionScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elegir Ampliada'));
      await tester.pumpAndSettle();

      expect(find.text('NAVIGATED_TO_cedula'), findsOneWidget);
    });

    testWidgets('selecting basica stores correct plan code and price', (
      tester,
    ) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestableWidget(
          const PlanSelectionScreen(),
          providerContainer: container,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elegir Básica'));
      await tester.pumpAndSettle();

      final state = container.read(onboardingProvider);
      expect(state.selectedPlan, 'basica');
      expect(state.premiumUsd, 17.00);
    });

    testWidgets('selecting plus stores correct plan code and price', (
      tester,
    ) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestableWidget(
          const PlanSelectionScreen(),
          providerContainer: container,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elegir Plus'));
      await tester.pumpAndSettle();

      final state = container.read(onboardingProvider);
      expect(state.selectedPlan, 'plus');
      expect(state.premiumUsd, 31.00);
    });

    testWidgets('selecting ampliada stores correct plan code and price', (
      tester,
    ) async {
      await _setTallViewport(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestableWidget(
          const PlanSelectionScreen(),
          providerContainer: container,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elegir Ampliada'));
      await tester.pumpAndSettle();

      final state = container.read(onboardingProvider);
      expect(state.selectedPlan, 'ampliada');
      expect(state.premiumUsd, 110.00);
    });
  });
}
