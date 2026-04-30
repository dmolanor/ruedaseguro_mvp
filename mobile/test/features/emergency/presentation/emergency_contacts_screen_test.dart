// Widget tests for EmergencyContactsScreen (RS-089/090)
//
// Uses emergencyContactsProvider override to inject fake contact data
// without requiring a live Supabase connection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/features/emergency/data/emergency_contact_repository.dart';
import 'package:ruedaseguro/features/emergency/presentation/screens/emergency_contacts_screen.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Builds the screen with the given contact list injected via provider override.
Widget _buildScreen({
  required List<EmergencyContact> contacts,
  bool onboardingMode = false,
}) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(
        path: '/test',
        builder: (_, __) =>
            EmergencyContactsScreen(onboardingMode: onboardingMode),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('NAVIGATED_TO_consent'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      emergencyContactsProvider.overrideWith((ref) async => contacts),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

EmergencyContact _makeContact({
  String id = 'c1',
  String fullName = 'María Pérez',
  String phone = '04141234567',
  String? relation = 'madre',
  bool isPrimary = false,
}) => EmergencyContact(
  id: id,
  profileId: 'profile-1',
  fullName: fullName,
  phone: phone,
  relation: relation,
  isPrimary: isPrimary,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('EmergencyContactsScreen — empty state', () {
    testWidgets('shows warning badge when no contacts', (tester) async {
      await tester.pumpWidget(_buildScreen(contacts: []));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Agrega al menos un contacto de emergencia para activar la protección en la calle.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows add-contact button when empty', (tester) async {
      await tester.pumpWidget(_buildScreen(contacts: []));
      await tester.pumpAndSettle();

      expect(find.text('Agregar contacto de emergencia'), findsOneWidget);
    });

    testWidgets(
      'onboarding mode: Continuar is disabled and hint shown when no contacts',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(contacts: [], onboardingMode: true),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Agrega al menos un contacto para continuar'),
          findsOneWidget,
        );

        final continuar = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continuar'),
        );
        expect(continuar.onPressed, isNull);
      },
    );
  });

  group('EmergencyContactsScreen — with contacts', () {
    testWidgets('renders contact name and phone', (tester) async {
      final contacts = [
        _makeContact(fullName: 'Carlos López', phone: '0416-9876543'),
      ];
      await tester.pumpWidget(_buildScreen(contacts: contacts));
      await tester.pumpAndSettle();

      expect(find.text('Carlos López'), findsOneWidget);
      expect(find.textContaining('0416-9876543'), findsOneWidget);
    });

    testWidgets('shows Principal badge for primary contact', (tester) async {
      final contacts = [
        _makeContact(fullName: 'Pedro Martínez', isPrimary: true),
      ];
      await tester.pumpWidget(_buildScreen(contacts: contacts));
      await tester.pumpAndSettle();

      expect(find.text('Principal'), findsOneWidget);
    });

    testWidgets('does not show Principal badge for non-primary', (
      tester,
    ) async {
      final contacts = [
        _makeContact(fullName: 'Ana Rodríguez', isPrimary: false),
      ];
      await tester.pumpWidget(_buildScreen(contacts: contacts));
      await tester.pumpAndSettle();

      expect(find.text('Principal'), findsNothing);
    });

    testWidgets('shows edit and delete icons per contact', (tester) async {
      final contacts = [_makeContact()];
      await tester.pumpWidget(_buildScreen(contacts: contacts));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('shows "Agregar otro contacto" when contacts exist', (
      tester,
    ) async {
      final contacts = [_makeContact()];
      await tester.pumpWidget(_buildScreen(contacts: contacts));
      await tester.pumpAndSettle();

      expect(find.text('Agregar otro contacto'), findsOneWidget);
    });

    testWidgets('hides add button when 5 contacts exist', (tester) async {
      final contacts = List.generate(
        5,
        (i) => _makeContact(id: 'c$i', fullName: 'Contacto $i'),
      );
      await tester.pumpWidget(_buildScreen(contacts: contacts));
      await tester.pumpAndSettle();

      expect(find.text('Agregar otro contacto'), findsNothing);
    });

    testWidgets('onboarding mode: Continuar is enabled when contacts exist', (
      tester,
    ) async {
      final contacts = [_makeContact()];
      await tester.pumpWidget(
        _buildScreen(contacts: contacts, onboardingMode: true),
      );
      await tester.pumpAndSettle();

      final continuar = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(continuar.onPressed, isNotNull);
    });

    testWidgets('onboarding mode: tapping Continuar navigates to consent', (
      tester,
    ) async {
      final contacts = [_makeContact()];
      await tester.pumpWidget(
        _buildScreen(contacts: contacts, onboardingMode: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('NAVIGATED_TO_consent'), findsOneWidget);
    });
  });

  group('EmergencyContactsScreen — relation labels', () {
    test('relationLabels map has expected human-readable values', () {
      expect(EmergencyContact.relationLabels['madre'], 'Mamá');
      expect(EmergencyContact.relationLabels['padre'], 'Papá');
      expect(EmergencyContact.relationLabels['pareja'], 'Pareja');
    });

    test('relationLabel falls back to relation key when not in map', () {
      final c = _makeContact(relation: 'abuelo');
      expect(c.relationLabel, 'abuelo');
    });

    test('relationLabel returns "Sin especificar" when relation is null', () {
      final c = _makeContact(relation: null);
      expect(c.relationLabel, 'Sin especificar');
    });
  });

  group('EmergencyContact.fromMap', () {
    test('parses all fields from a Supabase row', () {
      final row = {
        'id': 'uuid-1',
        'profile_id': 'profile-uuid',
        'full_name': 'Juan García',
        'phone': '+584141234567',
        'relation': 'pareja',
        'is_primary': true,
      };

      final contact = EmergencyContact.fromMap(row);

      expect(contact.id, 'uuid-1');
      expect(contact.profileId, 'profile-uuid');
      expect(contact.fullName, 'Juan García');
      expect(contact.phone, '+584141234567');
      expect(contact.relation, 'pareja');
      expect(contact.isPrimary, isTrue);
    });

    test('handles null relation gracefully', () {
      final row = {
        'id': 'uuid-2',
        'profile_id': 'p',
        'full_name': 'Ana',
        'phone': '04141111111',
        'relation': null,
        'is_primary': false,
      };

      final contact = EmergencyContact.fromMap(row);
      expect(contact.relation, isNull);
    });
  });
}
