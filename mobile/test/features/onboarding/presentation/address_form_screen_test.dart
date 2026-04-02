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
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Municipio'), findsOneWidget);
    });

    testWidgets('shows GPS detect button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detectar mi ubicación'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('Selecciona un estado'), findsOneWidget);
      expect(find.text('Selecciona un municipio'), findsOneWidget);
      expect(find.text('Requerido'), findsOneWidget); // urbanización
    });

    testWidgets('valid form navigates to consent screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      // Enter urbanización
      await tester.enterText(find.byType(TextFormField).first, 'El Paraíso');

      // Select Estado
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Distrito Capital').last);
      await tester.pumpAndSettle();

      // Select Municipio (now enabled after estado selected)
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Libertador').last);
      await tester.pumpAndSettle();

      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_consent'), findsOneWidget);
    });

    testWidgets('pre-fills urbanización from existing state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AddressFormScreen(),
          initialData: const OnboardingData(
            urbanizacion: 'La Candelaria',
            municipio: 'Libertador',
            estado: 'Distrito Capital',
            codigoPostal: '1010',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('La Candelaria'), findsOneWidget);
    });

    testWidgets('estado and municipio dropdowns are present', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
      expect(find.text('Selecciona tu estado'), findsOneWidget);
    });

    testWidgets('postal code is optional', (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(const AddressFormScreen()),
      );
      await tester.pumpAndSettle();

      // Enter urbanización only (no postal code)
      await tester.enterText(find.byType(TextFormField).first, 'Centro');

      // Select Estado
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Distrito Capital').last);
      await tester.pumpAndSettle();

      // Select Municipio
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Libertador').last);
      await tester.pumpAndSettle();

      // Leave postal code empty and submit
      await _tapContinuar(tester);

      expect(find.text('NAVIGATED_TO_consent'), findsOneWidget);
    });
  });
}
