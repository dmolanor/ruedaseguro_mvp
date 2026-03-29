import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:ruedaseguro/features/auth/data/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, authenticatedWithProfile, unauthenticated }

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

  @override
  RSAuthState build() {
    ref.onDispose(() => _subscription?.cancel());
    _init();
    return const RSAuthState(status: AuthStatus.initial);
  }

  Future<void> _init() async {
    final repo = AuthRepository.instance;
    final session = repo.getCurrentSession();
    if (session != null) {
      final hasProfile = await repo.profileExists();
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

    _subscription = repo.onAuthStateChange.listen((authState) async {
      final session = authState.session;
      if (session != null) {
        final hasProfile = await repo.profileExists();
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
    state = const RSAuthState(
      status: AuthStatus.authenticatedWithProfile,
    );
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

final authProvider = NotifierProvider<AuthNotifier, RSAuthState>(AuthNotifier.new);
