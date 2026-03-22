import 'package:flutter/material.dart';

class CedulaConfirmScreen extends StatelessWidget {
  const CedulaConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Identidad'),
      ),
      body: const Center(
        child: Text('Confirmar Identidad'),
      ),
    );
  }
}
