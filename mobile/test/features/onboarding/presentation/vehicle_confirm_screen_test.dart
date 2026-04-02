import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/vehicle_confirm_screen.dart';

import 'helpers/test_helpers.dart';

OnboardingData _stateWithVehicle({
  String plate = 'AB123CD',
  String brand = 'BERA',
  String model = 'BR150',
  int year = 2020,
  String vehicleUse = 'particular',
  CrossValidationResult? crossValidation,
  Map<String, double> confidences = const {},
}) {
  return OnboardingData(
    certificadoOcr: CertificadoParseResult(
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      confidence: 0.85,
      fieldConfidences: confidences,
    ),
    plate: plate,
    brand: brand,
    model: model,
    year: year,
    vehicleUse: vehicleUse,
    crossValidation: crossValidation,
  );
}

Future<void> _tapContinuar(WidgetTester tester) async {
  await tester.dragUntilVisible(
    find.text('Continuar'),
    find.byType(SingleChildScrollView),
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  group('VehicleConfirmScreen', () {
    testWidgets('renders vehicle fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirma los datos de tu moto'), findsOneWidget);
      expect(find.text('Placa'), findsOneWidget);
      expect(find.text('Marca'), findsOneWidget);
      expect(find.text('Modelo'), findsOneWidget);
      expect(find.text('Año'), findsOneWidget);
    });

    testWidgets('pre-fills OCR data', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            plate: 'XY456ZW',
            brand: 'HONDA',
            model: 'CBR250',
            year: 2022,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('XY456ZW'), findsOneWidget);
      expect(find.text('HONDA'), findsOneWidget);
      expect(find.text('CBR250'), findsOneWidget);
      expect(find.text('2022'), findsOneWidget);
    });

    testWidgets('validation fails for invalid plate', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(plate: 'INVALID'),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      // Scroll back up to see validation error (ListView lazy rendering)
      await tester.dragUntilVisible(
        find.text('Formato de placa inválido'),
        find.byType(SingleChildScrollView),
        const Offset(0, 200),
      );
      expect(find.text('Formato de placa inválido'), findsOneWidget);
    });

    testWidgets('validation fails for invalid year', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(year: 1900),
        ),
      );
      await tester.pumpAndSettle();

      // The year field has '1900', need to clear and enter invalid
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(3), '1900');

      await _tapContinuar(tester);

      expect(find.text('Año inválido'), findsOneWidget);
    });

    testWidgets('valid form navigates to vehicle-photo', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_vehicle_photo'), findsOneWidget);
    });

    testWidgets('shows verified banner on match', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            crossValidation: const CrossValidationResult(
              nameMatch: true,
              cedulaMatch: true,
              overallMatch: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Datos verificados'), findsOneWidget);
    });

    testWidgets('shows mismatch warning on cross-validation failure',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            crossValidation: const CrossValidationResult(
              nameMatch: false,
              cedulaMatch: true,
              overallMatch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('El nombre del propietario no coincide con la cédula'),
        findsOneWidget,
      );
    });

    testWidgets('button disabled on mismatch without legal rep', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            crossValidation: const CrossValidationResult(
              nameMatch: false,
              cedulaMatch: true,
              overallMatch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to button
      await tester.dragUntilVisible(
        find.text('Continuar'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final elevatedButton = find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('checking legal rep enables button on mismatch', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            crossValidation: const CrossValidationResult(
              nameMatch: false,
              cedulaMatch: true,
              overallMatch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Soy representante legal del propietario'));
      await tester.pumpAndSettle();

      // Scroll to button
      await tester.dragUntilVisible(
        find.text('Continuar'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final elevatedButton = find.ancestor(
        of: find.text('Continuar'),
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('no banner when cross-validation skipped', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            crossValidation: CrossValidationResult.skipped(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Datos verificados'), findsNothing);
      expect(find.textContaining('no coincide'), findsNothing);
    });

    testWidgets('shows amber hint for low-confidence fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VehicleConfirmScreen(),
          initialData: _stateWithVehicle(
            confidences: {'plate': 0.5, 'brand': 0.95},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifica este campo'), findsWidgets);
    });
  });
}
