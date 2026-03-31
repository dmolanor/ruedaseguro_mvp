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
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_confirm_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/licencia_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/licencia_confirm_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/carnet_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/vehicle_photo_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/vehicle_confirm_screen.dart';
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
import 'package:ruedaseguro/features/support/presentation/screens/create_ticket_screen.dart';

// Routes that don't require auth
const _publicRoutes = ['/welcome', '/login', '/otp'];

// Routes that require auth but no profile (onboarding in progress)
const _onboardingRoutes = [
  '/onboarding/cedula',
  '/onboarding/cedula/confirm',
  '/onboarding/licencia',
  '/onboarding/licencia/confirm',
  '/onboarding/registro',
  '/onboarding/vehicle-photo',
  '/onboarding/vehicle/confirm',
  '/onboarding/address',
  '/onboarding/consent',
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

      // Emergency and profile routes don't need auth redirect in debug/demo
      if (kDebugMode && location == '/emergency') return null;

      // While still checking session, stay on splash
      if (authState.status == AuthStatus.initial) {
        return location == '/splash' ? null : '/splash';
      }

      // Unauthenticated: must go to public routes
      if (authState.status == AuthStatus.unauthenticated) {
        if (_publicRoutes.contains(location)) return null;
        return '/welcome';
      }

      // Authenticated but no profile: welcome or onboarding
      if (authState.status == AuthStatus.authenticated) {
        if (_onboardingRoutes.contains(location)) return null;
        if (_publicRoutes.contains(location)) return null;
        return '/welcome';
      }

      // Fully authenticated with profile
      if (authState.status == AuthStatus.authenticatedWithProfile) {
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),

      // ── Main app shell (with bottom nav) ─────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ── Policy ───────────────────────────────────────────────
      GoRoute(
        path: '/policy/select',
        builder: (context, state) => const ProductSelectionScreen(),
      ),
      GoRoute(
        path: '/policy/quote',
        builder: (context, state) {
          final plan = state.extra as InsurancePlan?;
          return QuoteSummaryScreen(plan: plan);
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
        builder: (context, state) => PolicyDetailScreen(
          policyId: state.pathParameters['id']!,
        ),
      ),

      // ── Onboarding ───────────────────────────────────────────
      GoRoute(
        path: '/onboarding/cedula',
        builder: (context, state) => const CedulaScanScreen(),
      ),
      GoRoute(
        path: '/onboarding/cedula/confirm',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return CedulaConfirmScreen(ocrData: args);
        },
      ),
      GoRoute(
        path: '/onboarding/licencia',
        builder: (context, state) => const LicenciaScanScreen(),
      ),
      GoRoute(
        path: '/onboarding/licencia/confirm',
        builder: (context, state) => const LicenciaConfirmScreen(),
      ),
      GoRoute(
        path: '/onboarding/registro',
        builder: (context, state) => const CarnetScanScreen(),
      ),
      GoRoute(
        path: '/onboarding/vehicle-photo',
        builder: (context, state) => const VehiclePhotoScreen(),
      ),
      GoRoute(
        path: '/onboarding/vehicle/confirm',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return VehicleConfirmScreen(ocrData: args);
        },
      ),
      GoRoute(
        path: '/onboarding/address',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) => const ConsentScreen(),
      ),

      // ── Payment ──────────────────────────────────────────────
      GoRoute(
        path: '/payment/method',
        builder: (context, state) {
          final plan = state.extra as InsurancePlan?;
          return PaymentMethodScreen(plan: plan);
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

      // ── Emergency ────────────────────────────────────────────
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
    ],
  );
});

/// Triggers GoRouter redirect whenever [notify] is called.
class _RouterRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
