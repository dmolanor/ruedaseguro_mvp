import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/address_form_screen.dart';

import 'helpers/test_helpers.dart';

/// Scrolls down and taps the "Continuar" button.
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
  group('AddressFormScreen', () {
    testWidgets('renders header and required fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tu dirección'), findsOneWidget);
      expect(find.text('Urbanización / Sector'), findsOneWidget);
      expect(find.text('Ciudad'), findsOneWidget);
      expect(find.text('Municipio'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('Requerido'), findsNWidgets(3));
      expect(find.text('Selecciona un estado'), findsOneWidget);
    });

    testWidgets('valid form navigates to consent screen', (tester) async {
      // Use larger surface so dropdown has room for its popup
      await tester.binding.setSurfaceSize(const Size(411, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'El Paraíso');
      await tester.enterText(textFields.at(1), 'Caracas');
      await tester.enterText(textFields.at(2), 'Libertador');

      // Tap dropdown to open and select a state
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Distrito Capital').last);
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_consent'), findsOneWidget);
    });

    testWidgets('pre-fills fields from existing state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AddressFormScreen(),
          initialData: const OnboardingData(
            urbanizacion: 'La Candelaria',
            ciudad: 'Caracas',
            municipio: 'Libertador',
            estado: 'Distrito Capital',
            codigoPostal: '1010',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('La Candelaria'), findsOneWidget);
      expect(find.text('Caracas'), findsOneWidget);
      expect(find.text('Libertador'), findsOneWidget);
      expect(find.text('Distrito Capital'), findsOneWidget);
    });

    testWidgets('estado dropdown is present with hint', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      // Dropdown renders with its hint text
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Selecciona tu estado'), findsOneWidget);
    });

    testWidgets('postal code is optional', (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Centro');
      await tester.enterText(textFields.at(1), 'Caracas');
      await tester.enterText(textFields.at(2), 'Libertador');

      // Tap dropdown to open and select a state
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Distrito Capital').last);
      await tester.pumpAndSettle();

      // Leave postal code empty
      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_consent'), findsOneWidget);
    });
  });
}
