import 'package:flutter/material.dart';

class CarnetScanScreen extends StatelessWidget {
  const CarnetScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Carnet'),
      ),
      body: const Center(
        child: Text('Escanear Carnet'),
      ),
    );
  }
}
