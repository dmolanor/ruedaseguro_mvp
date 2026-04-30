import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';

/// Notifier that starts with custom initial data for testing.
class TestOnboardingNotifier extends OnboardingNotifier {
  final OnboardingData _initialData;
  TestOnboardingNotifier(this._initialData);

  @override
  OnboardingData build() => _initialData;
}

/// Wraps a widget with ProviderScope + MaterialApp.router + GoRouter
/// so it can be used in widget tests with navigation and Riverpod.
///
/// Pass [providerContainer] to use an external ProviderContainer — useful
/// when a test needs to read state from the provider after widget interactions.
/// When provided, [initialData] is ignored (set up overrides on the container
/// before calling this function).
Widget buildTestableWidget(
  Widget child, {
  OnboardingData? initialData,
  ProviderContainer? providerContainer,
}) {
  final overrides = [
    if (initialData != null)
      onboardingProvider.overrideWith(
        () => TestOnboardingNotifier(initialData),
      ),
  ];

  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (_, __) => child),
      // Sprint 4B routes
      GoRoute(
        path: '/onboarding/cedula',
        builder: (_, __) => const _DummyScreen('cedula'),
      ),
      GoRoute(
        path: '/onboarding/cedula/confirm',
        builder: (_, __) => const _DummyScreen('cedula_confirm'),
      ),
      GoRoute(
        path: '/onboarding/certificado',
        builder: (_, __) => const _DummyScreen('certificado'),
      ),
      GoRoute(
        path: '/onboarding/property-validation',
        builder: (_, __) => const _DummyScreen('property_validation'),
      ),
      GoRoute(
        path: '/onboarding/address',
        builder: (_, __) => const _DummyScreen('address'),
      ),
      GoRoute(
        path: '/onboarding/emergency-contacts',
        builder: (_, __) => const _DummyScreen('emergency_contacts'),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (_, __) => const _DummyScreen('consent'),
      ),
      GoRoute(path: '/home', builder: (_, __) => const _DummyScreen('home')),
      // Legacy stubs (for screens still referencing old routes)
      GoRoute(
        path: '/onboarding/licencia',
        builder: (_, __) => const _DummyScreen('licencia'),
      ),
      GoRoute(
        path: '/onboarding/licencia/confirm',
        builder: (_, __) => const _DummyScreen('licencia_confirm'),
      ),
      GoRoute(
        path: '/onboarding/registro',
        builder: (_, __) => const _DummyScreen('registro'),
      ),
      GoRoute(
        path: '/onboarding/vehicle-photo',
        builder: (_, __) => const _DummyScreen('vehicle_photo'),
      ),
    ],
  );

  if (providerContainer != null) {
    return UncontrolledProviderScope(
      container: providerContainer,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Dummy screen that displays its route name for navigation verification.
class _DummyScreen extends StatelessWidget {
  final String name;
  const _DummyScreen(this.name);

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('NAVIGATED_TO_$name')));
}
