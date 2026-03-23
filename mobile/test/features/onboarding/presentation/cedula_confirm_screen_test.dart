import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_confirm_screen.dart';

import 'helpers/test_helpers.dart';

OnboardingData _stateWithOcr({
  String idType = 'V',
  String idNumber = '12345678',
  String firstName = 'JUAN',
  String lastName = 'PEREZ',
  Map<String, double> confidences = const {},
}) {
  return OnboardingData(
    cedulaOcr: CedulaParseResult(
      idType: idType,
      idNumber: idNumber,
      firstName: firstName,
      lastName: lastName,
      confidence: 0.85,
      fieldConfidences: confidences,
    ),
    idType: idType,
    idNumber: idNumber,
    firstName: firstName,
    lastName: lastName,
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
  group('CedulaConfirmScreen', () {
    testWidgets('renders identity fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirma tus datos'), findsOneWidget);
      expect(find.text('Número de cédula'), findsOneWidget);
      expect(find.text('Nombre(s)'), findsOneWidget);
      expect(find.text('Apellido(s)'), findsOneWidget);
    });

    testWidgets('pre-fills OCR data', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(
            idNumber: '99887766',
            firstName: 'MARIA',
            lastName: 'GONZALEZ',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99887766'), findsOneWidget);
      expect(find.text('MARIA'), findsOneWidget);
      expect(find.text('GONZALEZ'), findsOneWidget);
    });

    testWidgets('validation fails for invalid cédula format', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(idNumber: '123'),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('Formato inválido (6-10 dígitos)'), findsOneWidget);
    });

    testWidgets('validation fails for short name', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(firstName: 'J', lastName: 'P'),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('Requerido (mín. 2 letras)'), findsWidgets);
    });

    testWidgets('valid form navigates to licencia screen', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_licencia'), findsOneWidget);
    });

    testWidgets('emergency contact section is collapsible', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(),
        ),
      );
      await tester.pumpAndSettle();

      // Hidden initially
      expect(find.text('Nombre del contacto'), findsNothing);

      // Scroll to and tap the collapsible header
      await tester.dragUntilVisible(
        find.text('Contacto de emergencia (opcional)'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.tap(find.text('Contacto de emergencia (opcional)'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre del contacto'), findsOneWidget);
    });

    testWidgets('shows amber hint for low-confidence fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CedulaConfirmScreen(),
          initialData: _stateWithOcr(
            confidences: {'idNumber': 0.5, 'firstName': 0.95},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifica este campo'), findsWidgets);
    });
  });
}
