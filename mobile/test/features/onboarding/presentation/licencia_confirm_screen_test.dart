import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/licencia_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/licencia_confirm_screen.dart';

import 'helpers/test_helpers.dart';

OnboardingData _stateWithLicencia({
  String licenciaNumber = '987654321',
  List<String> categories = const ['1°', '2°'],
  DateTime? expiryDate,
  String? bloodType = 'A+',
  Map<String, double> confidences = const {},
}) {
  return OnboardingData(
    licenciaOcr: LicenciaParseResult(
      licenciaNumber: licenciaNumber,
      categories: categories,
      expiryDate: expiryDate,
      bloodType: bloodType,
      confidence: 0.8,
      fieldConfidences: confidences,
    ),
    licenciaNumber: licenciaNumber,
    licenciaCategories: categories,
    licenciaExpiry: expiryDate,
    bloodType: bloodType,
  );
}

Future<void> _tapContinuar(WidgetTester tester) async {
  await tester.dragUntilVisible(
    find.text('Continuar'),
    find.byType(ListView),
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  group('LicenciaConfirmScreen', () {
    testWidgets('renders all license fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirma tu licencia'), findsOneWidget);
      expect(find.text('Número de licencia'), findsOneWidget);
      expect(find.text('Grados autorizados'), findsOneWidget);
    });

    testWidgets('shows all 5 grado filter chips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(5));
      expect(find.textContaining('1° Motos'), findsOneWidget);
      expect(find.textContaining('2° Autos'), findsOneWidget);
      expect(find.textContaining('3° Medianos'), findsOneWidget);
      expect(find.textContaining('4° Pesados'), findsOneWidget);
      expect(find.textContaining('5° Especiales'), findsOneWidget);
    });

    testWidgets('pre-selects grados from OCR data', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(categories: ['1°', '2°']),
        ),
      );
      await tester.pumpAndSettle();

      final chipList = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(chipList[0].selected, isTrue);  // 1°
      expect(chipList[1].selected, isTrue);  // 2°
      expect(chipList[2].selected, isFalse); // 3°
    });

    testWidgets('shows motorcycle warning when 1° not selected', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(categories: ['2°']),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Se requiere el 1° grado para conducir motocicletas'),
        findsOneWidget,
      );
    });

    testWidgets('hides motorcycle warning when 1° selected', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(categories: ['1°', '2°']),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Se requiere el 1° grado para conducir motocicletas'),
        findsNothing,
      );
    });

    testWidgets('toggling a grado chip updates selection', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(categories: ['1°']),
        ),
      );
      await tester.pumpAndSettle();

      // 3° should be unselected initially
      var chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(chips[2].selected, isFalse);

      // Tap 3°
      await tester.tap(find.textContaining('3° Medianos'));
      await tester.pumpAndSettle();

      chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(chips[2].selected, isTrue);
    });

    testWidgets('shows expired license warning for past date', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(expiryDate: DateTime(2020, 1, 1)),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find warning
      await tester.dragUntilVisible(
        find.textContaining('Tu licencia está vencida'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.textContaining('Tu licencia está vencida'), findsOneWidget);
    });

    testWidgets('no expired warning for future date', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(expiryDate: DateTime(2030, 12, 31)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tu licencia está vencida'), findsNothing);
    });

    testWidgets('validation fails for empty license number', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(licenciaNumber: ''),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('Requerido'), findsOneWidget);
    });

    testWidgets('valid form navigates to registro', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_registro'), findsOneWidget);
    });

    testWidgets('shows amber hint for low-confidence fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const LicenciaConfirmScreen(),
          initialData: _stateWithLicencia(
            confidences: {'licenciaNumber': 0.4},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifica este campo'), findsOneWidget);
    });
  });
}
