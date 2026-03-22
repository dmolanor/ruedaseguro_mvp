import 'package:flutter/material.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consentimiento Legal'),
      ),
      body: const Center(
        child: Text('Consentimiento Legal'),
      ),
    );
  }
}
