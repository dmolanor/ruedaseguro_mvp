import 'package:flutter/material.dart';

class VehicleConfirmScreen extends StatelessWidget {
  const VehicleConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Veh\u00edculo'),
      ),
      body: const Center(
        child: Text('Confirmar Veh\u00edculo'),
      ),
    );
  }
}
