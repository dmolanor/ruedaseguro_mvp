import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/consent_screen.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('ConsentScreen', () {
    testWidgets('renders all four consent checkboxes', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ConsentScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Términos y condiciones'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(4));
      expect(find.textContaining('Condiciones Generales del RCV'), findsOneWidget);
      expect(find.textContaining('veracidad'), findsOneWidget);
      expect(find.textContaining('antifraude'), findsOneWidget);
      expect(find.textContaining('Política de Privacidad'), findsOneWidget);
    });

    testWidgets('button is disabled when no consents given', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ConsentScreen()),
      );
      await tester.pumpAndSettle();

      // Find the "Finalizar registro" button
      final buttonFinder = find.text('Finalizar registro');
      expect(buttonFinder, findsOneWidget);

      // The button's ElevatedButton should be disabled (onPressed == null)
      final elevatedButton = find.ancestor(
        of: buttonFinder,
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('toggling all 4 checkboxes enables the button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ConsentScreen()),
      );
      await tester.pumpAndSettle();

      // Tap all 4 checkboxes
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        await tester.tap(checkboxes.at(i));
        await tester.pumpAndSettle();
      }

      // Button should now be enabled
      final buttonFinder = find.text('Finalizar registro');
      final elevatedButton = find.ancestor(
        of: buttonFinder,
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('button stays disabled if only 3 consents given', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ConsentScreen()),
      );
      await tester.pumpAndSettle();

      // Tap only 3 checkboxes
      final checkboxes = find.byType(Checkbox);
      for (int i = 0; i < 3; i++) {
        await tester.tap(checkboxes.at(i));
        await tester.pumpAndSettle();
      }

      final buttonFinder = find.text('Finalizar registro');
      final elevatedButton = find.ancestor(
        of: buttonFinder,
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('untoggling a consent re-disables the button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ConsentScreen()),
      );
      await tester.pumpAndSettle();

      // Check all 4
      final checkboxes = find.byType(Checkbox);
      for (int i = 0; i < 4; i++) {
        await tester.tap(checkboxes.at(i));
        await tester.pumpAndSettle();
      }

      // Uncheck the first one
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      final buttonFinder = find.text('Finalizar registro');
      final elevatedButton = find.ancestor(
        of: buttonFinder,
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('pre-populated consents from state enable button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ConsentScreen(),
          initialData: const OnboardingData(
            consentRcv: true,
            consentVeracidad: true,
            consentAntifraude: true,
            consentPrivacidad: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.text('Finalizar registro');
      final elevatedButton = find.ancestor(
        of: buttonFinder,
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ConsentScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Para emitir tu póliza necesitamos tu consentimiento'),
        findsOneWidget,
      );
    });
  });
}
