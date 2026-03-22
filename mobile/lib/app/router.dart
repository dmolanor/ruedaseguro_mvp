import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruedaseguro/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ruedaseguro/features/auth/presentation/screens/login_screen.dart';
import 'package:ruedaseguro/features/auth/presentation/screens/otp_screen.dart';
import 'package:ruedaseguro/features/home/presentation/screens/home_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/cedula_confirm_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/carnet_scan_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/vehicle_photo_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/vehicle_confirm_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/address_form_screen.dart';
import 'package:ruedaseguro/features/onboarding/presentation/screens/consent_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/product_selection_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/quote_summary_screen.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/policy_detail_screen.dart';
import 'package:ruedaseguro/features/payment/presentation/screens/payment_method_screen.dart';
import 'package:ruedaseguro/features/claims/presentation/screens/new_claim_screen.dart';
import 'package:ruedaseguro/features/profile/presentation/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      // Step 1: Welcome
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Step 2: Registration / Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Step 3: OTP Verification
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      // Step 4: Home
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Step 5: Product Selection
      GoRoute(
        path: '/policy/select',
        builder: (context, state) => const ProductSelectionScreen(),
      ),
      // Step 6a: Cédula Scan
      GoRoute(
        path: '/onboarding/cedula',
        builder: (context, state) => const CedulaScanScreen(),
      ),
      GoRoute(
        path: '/onboarding/cedula/confirm',
        builder: (context, state) => const CedulaConfirmScreen(),
      ),
      // Step 6b: Carnet Scan
      GoRoute(
        path: '/onboarding/carnet',
        builder: (context, state) => const CarnetScanScreen(),
      ),
      // Step 6c: Vehicle Photo
      GoRoute(
        path: '/onboarding/vehicle-photo',
        builder: (context, state) => const VehiclePhotoScreen(),
      ),
      GoRoute(
        path: '/onboarding/vehicle/confirm',
        builder: (context, state) => const VehicleConfirmScreen(),
      ),
      // Step 7: Address + Consent
      GoRoute(
        path: '/onboarding/address',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      // Step 7.5: Quote Summary
      GoRoute(
        path: '/policy/quote',
        builder: (context, state) => const QuoteSummaryScreen(),
      ),
      // Policy Detail
      GoRoute(
        path: '/policy/:id',
        builder: (context, state) => PolicyDetailScreen(
          policyId: state.pathParameters['id']!,
        ),
      ),
      // Step 8b: Payment
      GoRoute(
        path: '/payment/method',
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      // Claims
      GoRoute(
        path: '/claims/new',
        builder: (context, state) => const NewClaimScreen(),
      ),
      // Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
