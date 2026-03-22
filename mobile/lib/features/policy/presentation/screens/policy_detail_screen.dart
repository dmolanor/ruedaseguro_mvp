import 'package:flutter/material.dart';

class PolicyDetailScreen extends StatelessWidget {
  final String policyId;

  const PolicyDetailScreen({super.key, required this.policyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de P\u00f3liza'),
      ),
      body: Center(
        child: Text('P\u00f3liza: $policyId'),
      ),
    );
  }
}
