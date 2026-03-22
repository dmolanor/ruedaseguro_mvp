import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M\u00e9todo de Pago'),
      ),
      body: const Center(
        child: Text('M\u00e9todo de Pago'),
      ),
    );
  }
}
