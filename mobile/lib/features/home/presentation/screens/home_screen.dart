import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RuedaSeguro'),
      ),
      body: const Center(
        child: Text('\u00a1Cotizar ahora!'),
      ),
    );
  }
}
