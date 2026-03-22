import 'package:flutter/material.dart';

class QuoteSummaryScreen extends StatelessWidget {
  const QuoteSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Cotizaci\u00f3n'),
      ),
      body: const Center(
        child: Text('Resumen de Cotizaci\u00f3n'),
      ),
    );
  }
}
