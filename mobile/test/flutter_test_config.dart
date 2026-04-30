import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Runs once before every test file in this directory tree.
// Provides the minimum platform-channel stubs that widget tests need.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // GoTrueClient (inside Supabase.initialize) reads SharedPreferences.
  // Register an in-memory backend so the native channel is available in
  // the headless test runner.
  SharedPreferences.setMockInitialValues({});

  await initializeDateFormatting('es');

  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  } catch (_) {
    // Already initialized when multiple test files share the same process.
  }

  await testMain();
}
