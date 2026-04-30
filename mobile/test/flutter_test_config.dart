import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Runs once before every test file in this directory tree.
// Provides the minimum platform-channel stubs that widget tests need.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Must come before Supabase.initialize — without it, Supabase's
  // WidgetsFlutterBinding.ensureInitialized() call installs the production
  // binding first, which blocks TestWidgetsFlutterBinding from initializing
  // later (causing "Binding already initialized" assertions in testWidgets).
  TestWidgetsFlutterBinding.ensureInitialized();

  // GoTrueClient (inside Supabase.initialize) reads SharedPreferences.
  // Register an in-memory backend so the native channel is available in
  // the headless test runner.
  SharedPreferences.setMockInitialValues({});

  await initializeDateFormatting('es');

  // TestWidgetsFlutterBinding installs MockHttpOverrides globally, which
  // intercepts HttpClient creation and calls printOnFailure — a function
  // that requires being inside a test zone. Supabase.initialize() creates an
  // HttpClient in SupabaseClient's constructor, which runs here in
  // testExecutable (outside any test zone), causing it to throw.
  // Temporarily disable the mock overrides for the duration of initialization.
  final savedHttpOverrides = HttpOverrides.current;
  HttpOverrides.global = null;
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  } catch (_) {
    // v2.12.0 returns early when already initialized, so this only fires
    // if initialization truly fails — safe to swallow in test setup.
  } finally {
    HttpOverrides.global = savedHttpOverrides;
  }

  await testMain();
}
