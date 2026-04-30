import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:ruedaseguro/features/auth/data/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  authenticatedWithProfile,
  unauthenticated,
}

class RSAuthState {
  final AuthStatus status;
  final supa.User? user;
  final supa.Session? session;
  final String? errorMessage;

  const RSAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.session,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated ||
      status == AuthStatus.authenticatedWithProfile;

  bool get hasProfile => status == AuthStatus.authenticatedWithProfile;

  RSAuthState copyWith({
    AuthStatus? status,
    supa.User? user,
    supa.Session? session,
    String? errorMessage,
  }) {
    return RSAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<RSAuthState> {
  StreamSubscription<supa.AuthState>? _subscription;
  Timer? _initTimeout;

  @override
  RSAuthState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _initTimeout?.cancel();
    });
    _init();
    return const RSAuthState(status: AuthStatus.initial);
  }

  Future<void> _init() async {
    debugPrint('[AuthNotifier] _init start');
    final repo = AuthRepository.instance;

    // Hard safety net — state can NEVER remain `initial` beyond this point.
    // Stored as a cancellable Timer so tests (and fast dispose) don't leave a
    // pending future alive after the notifier is torn down.
    _initTimeout = Timer(const Duration(seconds: 12), () {
      if (state.status == AuthStatus.initial) {
        debugPrint(
          '[AuthNotifier] hard timeout fired — forcing unauthenticated',
        );
        final s = repo.getCurrentSession();
        state = s != null
            ? RSAuthState(
                status: AuthStatus.authenticatedWithProfile,
                user: s.user,
                session: s,
              )
            : const RSAuthState(status: AuthStatus.unauthenticated);
      }
    });

    try {
      final session = repo.getCurrentSession();
      debugPrint('[AuthNotifier] currentSession: ${session != null}');
      if (session != null) {
        debugPrint('[AuthNotifier] calling profileExists...');
        final hasProfile = await Future.any([
          repo.profileExists().catchError((_) => true),
          Future.delayed(const Duration(seconds: 5), () => true),
        ]);
        debugPrint('[AuthNotifier] hasProfile: $hasProfile');
        state = RSAuthState(
          status: hasProfile
              ? AuthStatus.authenticatedWithProfile
              : AuthStatus.authenticated,
          user: session.user,
          session: session,
        );
      } else {
        debugPrint('[AuthNotifier] no session — unauthenticated');
        state = const RSAuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('[AuthNotifier] _init error: $e');
      // Network error — recover based on cached session
      final session = repo.getCurrentSession();
      state = session != null
          ? RSAuthState(
              status: AuthStatus.authenticatedWithProfile,
              user: session.user,
              session: session,
            )
          : const RSAuthState(status: AuthStatus.unauthenticated);
    }

    _initTimeout?.cancel();
    debugPrint('[AuthNotifier] state after init: ${state.status}');

    _subscription = repo.onAuthStateChange.listen((authState) async {
      debugPrint('[AuthNotifier] stream event: ${authState.event}');
      final session = authState.session;
      if (session != null) {
        final hasProfile = await Future.any([
          repo.profileExists().catchError((_) => true),
          Future.delayed(const Duration(seconds: 5), () => true),
        ]);
        state = RSAuthState(
          status: hasProfile
              ? AuthStatus.authenticatedWithProfile
              : AuthStatus.authenticated,
          user: session.user,
          session: session,
        );
      } else {
        state = const RSAuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Called after profile is created during onboarding.
  void markProfileCreated() {
    if (state.isAuthenticated) {
      state = state.copyWith(status: AuthStatus.authenticatedWithProfile);
    }
  }

  /// Enter demo mode — skip auth entirely, jump to full app experience.
  void enterDemoMode() {
    state = const RSAuthState(status: AuthStatus.authenticatedWithProfile);
  }

  /// Enter onboarding demo mode — jump directly to onboarding flow.
  void enterOnboardingDemoMode() {
    state = const RSAuthState(status: AuthStatus.authenticated);
  }

  Future<void> signOut() async {
    try {
      await AuthRepository.instance.signOut();
    } catch (_) {
      // In demo mode there's no real session — ignore errors.
    }
    state = const RSAuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, RSAuthState>(
  AuthNotifier.new,
);
