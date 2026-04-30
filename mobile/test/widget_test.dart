import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ruedaseguro/app/app.dart';

void main() {
  setUpAll(() async {
    // Supabase.initialize uses SharedPreferences internally (GoTrue session
    // storage). Register the in-memory mock so the plugin channel is available
    // in the headless test runner.
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es');
    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // Already initialized in a previous test run in the same process.
    }
  });

  testWidgets('App smoke test — mounts without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    // pumpAndSettle drains the fake-timer queue. The auth_provider 12-second
    // safety-net timer is now a cancellable Timer cancelled once _init
    // completes, so pumpAndSettle will settle quickly.
    await tester.pumpAndSettle();
    expect(find.byType(App), findsOneWidget);
  });
}
