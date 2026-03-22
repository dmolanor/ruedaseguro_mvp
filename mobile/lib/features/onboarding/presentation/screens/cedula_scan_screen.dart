import 'package:flutter/material.dart';

class CedulaScanScreen extends StatelessWidget {
  const CedulaScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear C\u00e9dula'),
      ),
      body: const Center(
        child: Text('Escanear C\u00e9dula'),
      ),
    );
  }
}
