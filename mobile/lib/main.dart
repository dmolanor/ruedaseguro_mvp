import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ruedaseguro/app/app.dart';
import 'package:ruedaseguro/core/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  await initializeDateFormatting('es');

  // RS-070: Sentry crash reporting.
  // Skipped entirely in debug mode — Sentry's native Android SDK init blocks
  // the platform thread for 1.5–4s on MIUI devices, stalling MethodChannel
  // replies (including Supabase SecureStorage) and freezing the splash screen.
  if (!kDebugMode && EnvConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvConfig.sentryDsn;
        options.environment = 'production';
        options.tracesSampleRate = 0.1;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
      },
      appRunner: () => runApp(const ProviderScope(child: App())),
    );
  } else {
    runApp(const ProviderScope(child: App()));
  }
}
