import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/property_validation_screen.dart';

import 'helpers/test_helpers.dart';

/// Creates OnboardingData with a certificado that has an owner name.
OnboardingData _stateWithOwnerName([String ownerName = 'CARLOS RODRIGUEZ']) {
  return OnboardingData(
    certificadoOcr: CertificadoParseResult(
      ownerName: ownerName,
      confidence: 0.9,
    ),
  );
}

/// Pump the widget and advance past all flutter_animate animations on this
/// screen (max delay=200ms + duration=400ms = 600ms), then settle.
Future<void> _pumpScreen(
  WidgetTester tester,
  Widget widget, {
  OnboardingData? initialData,
}) async {
  await tester.pumpWidget(
    buildTestableWidget(widget, initialData: initialData),
  );
  // Advance past the longest animation (delay 200ms + duration 400ms)
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

void main() {
  group('PropertyValidationScreen', () {
    testWidgets('renders header and choice cards', (tester) async {
      await _pumpScreen(
        tester,
        const PropertyValidationScreen(),
        initialData: _stateWithOwnerName(),
      );

      expect(find.textContaining('La moto está a nombre'), findsOneWidget);
      expect(find.text('Soy el dueño'), findsOneWidget);
      expect(find.text('Soy conductor habitual'), findsOneWidget);
    });

    testWidgets('shows owner name from certificado', (tester) async {
      await _pumpScreen(
        tester,
        const PropertyValidationScreen(),
        initialData: _stateWithOwnerName('PEDRO HERNANDEZ'),
      );

      expect(find.textContaining('PEDRO HERNANDEZ'), findsOneWidget);
    });

    testWidgets('shows generic text when owner name is empty', (tester) async {
      await _pumpScreen(
        tester,
        const PropertyValidationScreen(),
        initialData: const OnboardingData(),
      );

      expect(
        find.text('El nombre del propietario no coincide con tu cédula.'),
        findsOneWidget,
      );
    });

    // ── Path A: Soy el dueño ──────────────────────────────────────

    testWidgets('Path A — "Soy el dueño" navigates to address screen', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const PropertyValidationScreen(),
        initialData: _stateWithOwnerName(),
      );

      await tester.tap(find.text('Soy el dueño'));
      await tester.pumpAndSettle();

      expect(find.text('NAVIGATED_TO_address'), findsOneWidget);
    });

    testWidgets('Path A — sets isHabitualDriver = false', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestableWidget(
          const PropertyValidationScreen(),
          providerContainer: container,
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Soy el dueño'));
      await tester.pumpAndSettle();

      expect(container.read(onboardingProvider).isHabitualDriver, isFalse);
    });

    // ── Path B: Soy conductor habitual ────────────────────────────

    testWidgets('Path B — "Soy conductor habitual" shows bottom sheet', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const PropertyValidationScreen(),
        initialData: _stateWithOwnerName(),
      );

      await tester.tap(find.text('Soy conductor habitual'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué significa esto para tu póliza?'), findsOneWidget);
    });

    testWidgets(
      'Path B — bottom sheet explains RCV vs accident coverage split',
      (tester) async {
        await _pumpScreen(
          tester,
          const PropertyValidationScreen(),
          initialData: _stateWithOwnerName(),
        );

        await tester.tap(find.text('Soy conductor habitual'));
        await tester.pumpAndSettle();

        expect(find.textContaining('RCV'), findsWidgets);
        expect(find.textContaining('accidentes personales'), findsOneWidget);
      },
    );

    testWidgets('Path B — sheet CTA navigates to owner cedula scan', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        const PropertyValidationScreen(),
        initialData: _stateWithOwnerName(),
      );

      await tester.tap(find.text('Soy conductor habitual'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escanear cédula del dueño'));
      await tester.pumpAndSettle();

      // '/onboarding/cedula?ownerMode=true' maps to the cedula stub
      expect(find.text('NAVIGATED_TO_cedula'), findsOneWidget);
    });

    testWidgets(
      'Path B — sheet cancel button closes sheet without navigating',
      (tester) async {
        await _pumpScreen(
          tester,
          const PropertyValidationScreen(),
          initialData: _stateWithOwnerName(),
        );

        await tester.tap(find.text('Soy conductor habitual'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // Back to the property validation screen, not navigated away
        expect(find.text('Soy el dueño'), findsOneWidget);
        expect(find.text('Soy conductor habitual'), findsOneWidget);
      },
    );
  });
}
