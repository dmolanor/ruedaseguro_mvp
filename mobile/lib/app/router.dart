import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/core/data/mock_data.dart';

import 'package:ruedaseguro/features/auth/presentation/screens/splash_screen.dart';
import 'package:ruedaseguro/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ruedaseguro/features/auth/presentation/screens/login_screen.dart';
import 'package:ruedaseguro/features/auth/presentation/screens/otp_screen.dart';
import 'package:ruedaseguro/features/home/presentation/screens/home_screen.dart';

// Onboarding — Sprint 4B: Plan-first + conductor habitual flow
import 'package:ruedaseguro/features/onboarding/presentation/screens/plan_selection_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_confirm_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/certificado_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/certificado_confirm_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/property_validation_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/address_form_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/consent_screen.dart';

import 'package:ruedaseguro/features/policy/presentation/screens/product_selection_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/quote_summary_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/policy_detail_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/emission_screen.dart';
import 'package:ruedaseguro/features/payment/presentation/screens/payment_method_screen.dart';
import 'package:ruedaseguro/features/payment/presentation/screens/payment_success_screen.dart';
import 'package:ruedaseguro/features/claims/presentation/screens/new_claim_screen.dart';
import 'package:ruedaseguro/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:ruedaseguro/features/emergency/presentation/screens/emergency_contacts_screen.dart';
import 'package:ruedaseguro/features/emergency/presentation/screens/emergency_setup_screen.dart';
import 'package:ruedaseguro/features/support/presentation/screens/create_ticket_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/policy_carnet_screen.dart';
import 'package:ruedaseguro/features/telemetry/presentation/screens/crash_monitor_screen.dart';

// Routes that don't require auth
const _publicRoutes = ['/welcome', '/login', '/otp'];

// Routes that require auth but no profile (onboarding in progress)
// Sprint 4B: Plan selection → Cédula → Certificado → [Property validation] → Address → Emergency contacts → Consent
const _onboardingRoutes = [
  '/onboarding/plan',
  '/onboarding/cedula',
  '/onboarding/cedula/confirm',
  '/onboarding/certificado',
  '/onboarding/certificado/confirm',
  '/onboarding/property-validation',
  '/onboarding/address',
  '/onboarding/emergency-contacts',
  '/onboarding/consent',
];

// Post-onboarding checkout — allowed for both authenticated (new user completing
// first purchase) and authenticatedWithProfile (renewals / upgrades).
const _checkoutRoutes = [
  '/policy/quote',
  '/payment/method',
  '/policy/emission',
];

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _RouterRefreshListenable();
  ref.listen<RSAuthState>(authProvider, (_, __) => listenable.notify());
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      if (kDebugMode && location == '/emergency') return null;

      if (authState.status == AuthStatus.initial) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (_publicRoutes.contains(location)) return null;
        return '/welcome';
      }

      if (authState.status == AuthStatus.authenticated) {
        if (_onboardingRoutes.contains(location)) return null;
        if (_checkoutRoutes.contains(location)) return null;
        if (_publicRoutes.contains(location)) return null;
        return '/welcome';
      }

      if (authState.status == AuthStatus.authenticatedWithProfile) {
        if (location == '/splash') return '/home';
        if (_publicRoutes.contains(location)) return '/home';
        if (_onboardingRoutes.contains(location)) return '/home';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),

      // ── Main app shell ────────────────────────────────────────
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      // ── Policy ───────────────────────────────────────────────
      GoRoute(
        path: '/policy/select',
        builder: (context, state) => const ProductSelectionScreen(),
      ),
      GoRoute(
        path: '/policy/quote',
        builder: (context, state) {
          final extra = state.extra;
          final InsurancePlan? plan;
          final bool fromOnboarding;
          if (extra is Map<String, dynamic>) {
            plan = extra['plan'] as InsurancePlan?;
            fromOnboarding = extra['fromOnboarding'] as bool? ?? false;
          } else {
            plan = extra as InsurancePlan?;
            fromOnboarding = false;
          }
          return QuoteSummaryScreen(plan: plan, fromOnboarding: fromOnboarding);
        },
      ),
      GoRoute(
        path: '/policy/emission',
        builder: (context, state) {
          final payload = state.extra as Map<String, dynamic>?;
          return EmissionScreen(payload: payload);
        },
      ),
      GoRoute(
        path: '/policy/:id',
        builder: (context, state) =>
            PolicyDetailScreen(policyId: state.pathParameters['id']!),
      ),

      // ── Onboarding — Sprint 4B (plan-first + conductor habitual) ───
      GoRoute(
        path: '/onboarding/plan',
        builder: (context, state) => const PlanSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/cedula',
        builder: (context, state) {
          final ownerMode = state.uri.queryParameters['ownerMode'] == 'true';
          return CedulaScanScreen(isOwnerScan: ownerMode);
        },
      ),
      GoRoute(
        path: '/onboarding/cedula/confirm',
        builder: (context, state) {
          final ownerMode = state.uri.queryParameters['ownerMode'] == 'true';
          final args = state.extra as Map<String, dynamic>?;
          return CedulaConfirmScreen(ocrData: args, isOwnerScan: ownerMode);
        },
      ),
      GoRoute(
        path: '/onboarding/certificado',
        builder: (context, state) => const CertificadoScanScreen(),
      ),
      GoRoute(
        path: '/onboarding/certificado/confirm',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return CertificadoConfirmScreen(ocrData: args);
        },
      ),
      GoRoute(
        path: '/onboarding/property-validation',
        builder: (context, state) => const PropertyValidationScreen(),
      ),
      GoRoute(
        path: '/onboarding/address',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/onboarding/emergency-contacts',
        builder: (context, state) =>
            const EmergencyContactsScreen(onboardingMode: true),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) => const ConsentScreen(),
      ),

      // ── Payment ──────────────────────────────────────────────
      GoRoute(
        path: '/payment/method',
        builder: (context, state) {
          final extra = state.extra;
          final InsurancePlan? plan;
          final bool fromOnboarding;
          if (extra is Map<String, dynamic>) {
            plan = extra['plan'] as InsurancePlan?;
            fromOnboarding = extra['fromOnboarding'] as bool? ?? false;
          } else {
            plan = extra as InsurancePlan?;
            fromOnboarding = false;
          }
          return PaymentMethodScreen(
            plan: plan,
            fromOnboarding: fromOnboarding,
          );
        },
      ),
      GoRoute(
        path: '/payment/success',
        builder: (context, state) {
          final plan = state.extra as InsurancePlan?;
          return PaymentSuccessScreen(plan: plan);
        },
      ),

      // ── Claims ───────────────────────────────────────────────
      GoRoute(
        path: '/claims/new',
        builder: (context, state) => const NewClaimScreen(),
      ),

      // ── Support ──────────────────────────────────────────────
      GoRoute(
        path: '/support/new-ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),

      // ── Profile settings ─────────────────────────────────────
      GoRoute(
        path: '/profile/emergency-contacts',
        builder: (context, state) =>
            const EmergencyContactsScreen(onboardingMode: false),
      ),

      // ── Policy carnet (QR digital card) ──────────────────────
      GoRoute(
        path: '/policy/:id/carnet',
        builder: (context, state) {
          final policyId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return PolicyCarnetScreen(policyId: policyId, extra: extra);
        },
      ),

      // ── Telemetry / IoT demo ─────────────────────────────────
      GoRoute(
        path: '/telemetry/crash-monitor',
        builder: (context, state) => const CrashMonitorScreen(),
      ),

      // ── Emergency ────────────────────────────────────────────
      GoRoute(
        path: '/emergency',
        builder: (context, state) {
          final activation = state.extra as EmergencyActivationType?;
          return EmergencyScreen(
            activationType: activation ?? EmergencyActivationType.manual,
          );
        },
      ),
      GoRoute(
        path: '/emergency/setup',
        builder: (context, state) {
          final fromOnboarding =
              state.uri.queryParameters['fromOnboarding'] == 'true';
          return EmergencySetupScreen(fromOnboarding: fromOnboarding);
        },
      ),
    ],
  );
});

class _RouterRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
