import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final Session? session;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.session,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    Session? session,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      session: session ?? this.session,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription<AuthState>? _subscription;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Check current session
    final session = SupabaseService.auth.currentSession;
    if (session != null) {
      state = AuthState(
        isAuthenticated: true,
        user: session.user,
        session: session,
      );
    }

    // Listen to auth state changes
    _subscription = SupabaseService.auth.onAuthStateChange.map((data) {
      final session = data.session;
      return AuthState(
        isAuthenticated: session != null,
        user: session?.user,
        session: session,
      );
    }).listen((authState) {
      state = authState;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
