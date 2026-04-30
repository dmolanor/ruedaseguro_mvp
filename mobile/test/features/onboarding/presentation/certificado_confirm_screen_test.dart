import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/certificado_confirm_screen.dart';

import 'helpers/test_helpers.dart';

/// State with a cross-validation mismatch (names don't match).
OnboardingData _stateWithMismatch() {
  return OnboardingData(
    plate: 'ABC-123-DE',
    brand: 'HONDA',
    model: 'CBR600',
    year: 2020,
    certificadoOcr: const CertificadoParseResult(
      plate: 'ABC-123-DE',
      ownerName: 'CARLOS RODRIGUEZ',
      vehicleType: 'MOTO PARTICULAR',
      confidence: 0.9,
    ),
    crossValidation: const CrossValidationResult(
      overallMatch: false,
      nameMatch: false,
      cedulaMatch: false,
      vehicleTypeOk: true,
      mismatchDetails:
          'El nombre del propietario no coincide con el nombre en la cédula.',
    ),
  );
}

/// State with a cross-validation that passes (names match).
OnboardingData _stateWithMatch() {
  return OnboardingData(
    plate: 'ABC-123-DE',
    brand: 'HONDA',
    model: 'CBR600',
    year: 2020,
    certificadoOcr: const CertificadoParseResult(
      plate: 'ABC-123-DE',
      ownerName: 'JUAN PEREZ',
      vehicleType: 'MOTO PARTICULAR',
      confidence: 0.9,
    ),
    crossValidation: const CrossValidationResult(
      overallMatch: true,
      nameMatch: true,
      cedulaMatch: true,
      vehicleTypeOk: true,
    ),
  );
}

/// State where the vehicle type is wrong (non-moto) — blocks submission.
OnboardingData _stateWithVehicleTypeMismatch() {
  return OnboardingData(
    plate: 'ABC-123-DE',
    brand: 'TOYOTA',
    model: 'COROLLA',
    year: 2020,
    certificadoOcr: const CertificadoParseResult(
      plate: 'ABC-123-DE',
      vehicleType: 'CARRO',
      confidence: 0.9,
    ),
    crossValidation: const CrossValidationResult(
      overallMatch: false,
      nameMatch: false,
      cedulaMatch: false,
      vehicleTypeOk: false,
      mismatchDetails: 'Tipo de vehículo no es motocicleta.',
    ),
  );
}

void main() {
  group('CertificadoConfirmScreen — Sprint 4B', () {
    testWidgets('renders screen title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirma los datos del vehículo'), findsOneWidget);
    });

    testWidgets('shows success banner when validation passes', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Propietario verificado con tu cédula'), findsOneWidget);
    });

    testWidgets('mismatch banner shows amber info text, not blocking error', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMismatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El propietario no coincide — lo resolveremos en el siguiente paso',
        ),
        findsOneWidget,
      );
      // Informational sub-text
      expect(find.textContaining('Puedes continuar'), findsOneWidget);
    });

    testWidgets('mismatch does NOT show a checkbox', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMismatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      // Also confirm the old "representante legal" label is gone
      expect(find.textContaining('representante'), findsNothing);
    });

    testWidgets('mismatch still has an enabled Continuar button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMismatch(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to the button
      await tester.dragUntilVisible(
        find.text('Continuar'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(
              of: find.text('Continuar'),
              matching: find.byType(ElevatedButton),
            )
            .last,
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('vehicle type wrong shows red error banner', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithVehicleTypeMismatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Solo se pueden asegurar motos'),
        findsOneWidget,
      );
    });

    testWidgets('vehicle type wrong disables Continuar button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithVehicleTypeMismatch(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Continuar'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find
            .ancestor(
              of: find.text('Continuar'),
              matching: find.byType(ElevatedButton),
            )
            .last,
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows rescan cédula button when there is a name mismatch', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMismatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Volver a escanear cédula'), findsOneWidget);
    });

    testWidgets('plate field pre-fills from state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CertificadoConfirmScreen(),
          initialData: _stateWithMatch(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABC-123-DE'), findsWidgets);
    });
  });
}
