import 'package:flutter/material.dart';

class VehiclePhotoScreen extends StatelessWidget {
  const VehiclePhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto del Veh\u00edculo'),
      ),
      body: const Center(
        child: Text('Foto del Veh\u00edculo'),
      ),
    );
  }
}
