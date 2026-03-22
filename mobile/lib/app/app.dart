import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruedaseguro/app/router.dart';
import 'package:ruedaseguro/core/theme/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RuedaSeguro',
      debugShowCheckedModeBanner: false,
      theme: rsTheme,
      routerConfig: router,
      locale: const Locale('es', 'VE'),
    );
  }
}
