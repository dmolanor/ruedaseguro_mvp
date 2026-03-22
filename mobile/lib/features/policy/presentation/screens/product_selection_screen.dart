import 'package:flutter/material.dart';

class ProductSelectionScreen extends StatelessWidget {
  const ProductSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Producto'),
      ),
      body: const Center(
        child: Text('Seleccionar Producto'),
      ),
    );
  }
}
