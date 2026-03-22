import 'package:flutter/material.dart';

class NewClaimScreen extends StatelessWidget {
  const NewClaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reclamo'),
      ),
      body: const Center(
        child: Text('Nuevo Reclamo'),
      ),
    );
  }
}
