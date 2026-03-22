import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a RuedaSeguro'),
      ),
      body: const Center(
        child: Text('Si te caes, no est\u00e1s solo.'),
      ),
    );
  }
}
