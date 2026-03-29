/// Centralized mock data for demo/presentation mode.
/// All data here is fake — used to populate screens before backend integration.
library;

import 'package:flutter/material.dart';

// ─── Rider Profile ───────────────────────────────────────────────
class MockRider {
  static const firstName = 'Juan Carlos';
  static const lastName = 'Rodríguez';
  static const fullName = 'Juan Carlos Rodríguez';
  static const phone = '+58 424-1234567';
  static const email = 'jcrodriguez@email.com';
  static const idType = 'V';
  static const idNumber = '12.345.678';
  static const nationality = 'Venezolano';
  static const dateOfBirth = '15/03/1992';
  static const age = 34;
  static const address = 'Urb. El Paraíso, Calle 4, Casa 12';
  static const city = 'Caracas';
  static const state = 'Distrito Capital';
  static const postalCode = '1010';
  static const emergencyContact = 'María Rodríguez';
  static const emergencyPhone = '+58 412-9876543';
  static const emergencyRelation = 'Madre';
}

// ─── Vehicle ─────────────────────────────────────────────────────
class MockVehicle {
  static const brand = 'Honda';
  static const model = 'CBF 150';
  static const year = 2022;
  static const color = 'Rojo';
  static const plate = 'ABC-123-DE';
  static const serialMotor = 'HC150M22A001234';
  static const serialCarroceria = 'HC150C22B005678';
  static const use = 'Particular';
}

// ─── Policy ──────────────────────────────────────────────────────
class MockPolicy {
  static const number = 'RS-2026-001234';
  static const type = 'RCV Plus';
  static const tier = 'plus'; // basica, plus, ampliada
  static const status = 'Activa';
  static const carrier = 'Seguros Pirámide';
  static const broker = 'Correduría Nacional';
  static const issueDate = '23 Mar 2026';
  static const expiryDate = '23 Mar 2027';
  static const premiumUsd = 31.00;
  static const premiumVes = 2430.50;
  static const sha256Hash = 'a7f3c8d2e1b4f6a9c0d5e8f7b2a1c4d6e3f0a9b8c7d6e5f4a3b2c1d0e9f8a7';
  static const coverages = [
    'Responsabilidad Civil Vehicular (RCV)',
    'Daños a terceros hasta \$5,000',
    'Asistencia en grúa 24/7',
    'Defensa legal y penal',
    'Gastos médicos conductor \$2,000',
  ];
}

// ─── Coverage Item (name + sum assured) ──────────────────────────
class CoverageItem {
  final String name;
  final String sa; // e.g. "$ 5,000 USD" or "Incluida"

  const CoverageItem(this.name, this.sa);
}

// ─── Insurance Plans ─────────────────────────────────────────────
class InsurancePlan {
  final String id;
  final String name;
  final String shortName;
  final double priceUsd;
  final String targetMarket;
  final List<String> coverages;
  final List<String> excluded;
  final List<CoverageItem> coverageItems;
  final bool isRecommended;
  final Color accentColor;
  final IconData icon;
  // DB-backed fields (null for mock/demo data)
  final String tier;           // 'basica' | 'plus' | 'ampliada'
  final String? policyTypeId;  // UUID from policy_types table
  final String? carrierId;     // UUID from carriers table

  const InsurancePlan({
    required this.id,
    required this.name,
    required this.shortName,
    required this.priceUsd,
    required this.targetMarket,
    required this.coverages,
    this.excluded = const [],
    this.coverageItems = const [],
    this.isRecommended = false,
    required this.accentColor,
    required this.icon,
    this.tier = '',
    this.policyTypeId,
    this.carrierId,
  });

  double get priceMonthlyUsd => priceUsd / 12;
}

class MockPlans {
  static const exchangeRate = 78.50; // 1 USD = 78.50 VES (BCV)

  static final basica = InsurancePlan(
    id: 'basica',
    tier: 'basica',
    name: 'RCV Básica',
    shortName: 'Básica',
    priceUsd: 17.00,
    targetMarket: '70% del mercado',
    coverages: [
      'Responsabilidad Civil Vehicular',
      'Daños a terceros hasta \$3,000',
      'Cobertura legal mínima',
    ],
    excluded: [
      'Sin grúa',
      'Sin gastos médicos',
      'Sin defensa legal',
    ],
    coverageItems: const [
      CoverageItem('Daños a cosas de terceros', '\$ 3,000 USD'),
      CoverageItem('Daños a personas de terceros', '\$ 5,000 USD'),
      CoverageItem('Asistencia legal mínima', 'Incluida'),
      CoverageItem('Exceso de límite', 'No incluido'),
      CoverageItem('Grúa 24/7', 'No incluido'),
      CoverageItem('Gastos médicos conductor', 'No incluido'),
    ],
    accentColor: const Color(0xFF5C6BC0),
    icon: Icons.shield_outlined,
  );

  static final plus = InsurancePlan(
    id: 'plus',
    tier: 'plus',
    name: 'RCV Plus',
    shortName: 'Plus',
    priceUsd: 31.00,
    targetMarket: '30% del mercado',
    coverages: [
      'Responsabilidad Civil Vehicular',
      'Daños a terceros hasta \$5,000',
      'Asistencia en grúa 24/7',
      'Defensa legal y penal',
      'Gastos médicos conductor \$2,000',
    ],
    coverageItems: const [
      CoverageItem('Daños a cosas de terceros', '\$ 5,000 USD'),
      CoverageItem('Daños a personas de terceros', '\$ 10,000 USD'),
      CoverageItem('Asistencia legal y penal', 'Incluida'),
      CoverageItem('Exceso de límite', '\$ 2,000 USD'),
      CoverageItem('Grúa 24/7', 'Incluida'),
      CoverageItem('Gastos médicos conductor', '\$ 2,000 USD'),
    ],
    isRecommended: true,
    accentColor: const Color(0xFFFF6D00),
    icon: Icons.verified_user_rounded,
  );

  static final ampliada = InsurancePlan(
    id: 'ampliada',
    tier: 'ampliada',
    name: 'Cobertura Ampliada',
    shortName: 'Ampliada',
    priceUsd: 110.00,
    targetMarket: '5% del mercado',
    coverages: [
      'Responsabilidad Civil Vehicular',
      'Daños a terceros hasta \$15,000',
      'Asistencia en grúa 24/7 + vehículo sustituto',
      'Defensa legal y penal completa',
      'Gastos médicos conductor \$10,000',
      'Acceso Red ALTEHA (350+ clínicas)',
      'Indemnización por hospitalización',
      'Cobertura por robo y hurto',
    ],
    coverageItems: const [
      CoverageItem('Daños a cosas de terceros', '\$ 15,000 USD'),
      CoverageItem('Daños a personas de terceros', '\$ 25,000 USD'),
      CoverageItem('Asistencia legal y penal completa', 'Incluida'),
      CoverageItem('Exceso de límite', '\$ 10,000 USD'),
      CoverageItem('Grúa 24/7 + vehículo sustituto', 'Incluida'),
      CoverageItem('Gastos médicos conductor', '\$ 10,000 USD'),
      CoverageItem('Hospitalización (Red ALTEHA)', '\$ 5,000 USD'),
      CoverageItem('Robo y hurto', 'Valor de mercado'),
    ],
    accentColor: const Color(0xFF1A237E),
    icon: Icons.workspace_premium_rounded,
  );

  static List<InsurancePlan> get all => [basica, plus, ampliada];
}

// ─── Claims ──────────────────────────────────────────────────────
class MockClaim {
  final String id;
  final String type;
  final String status;
  final String date;
  final String description;
  final Color statusColor;
  final IconData statusIcon;

  const MockClaim({
    required this.id,
    required this.type,
    required this.status,
    required this.date,
    required this.description,
    required this.statusColor,
    required this.statusIcon,
  });
}

class MockClaims {
  static const claims = [
    MockClaim(
      id: 'SIN-2026-0042',
      type: 'Colisión menor',
      status: 'En revisión',
      date: '15 Mar 2026',
      description: 'Colisión lateral en Av. Bolívar con daños menores al espejo retrovisor.',
      statusColor: Color(0xFFFFB300),
      statusIcon: Icons.hourglass_top_rounded,
    ),
    MockClaim(
      id: 'SIN-2025-0187',
      type: 'Daño a tercero',
      status: 'Liquidado',
      date: '08 Nov 2025',
      description: 'Raspón en vehículo estacionado en CC Sambil. Liquidación completada.',
      statusColor: Color(0xFF2E7D32),
      statusIcon: Icons.check_circle_rounded,
    ),
  ];
}

// ─── Payments ────────────────────────────────────────────────────
class MockPayment {
  final String reference;
  final String method;
  final double amountUsd;
  final String date;
  final String status;

  const MockPayment({
    required this.reference,
    required this.method,
    required this.amountUsd,
    required this.date,
    required this.status,
  });
}

class MockPayments {
  static const history = [
    MockPayment(
      reference: 'PAG-2026-001234',
      method: 'Pago Móvil',
      amountUsd: 31.00,
      date: '23 Mar 2026',
      status: 'Confirmado',
    ),
    MockPayment(
      reference: 'PAG-2025-004521',
      method: 'Transferencia',
      amountUsd: 28.00,
      date: '23 Mar 2025',
      status: 'Confirmado',
    ),
  ];
}

// ─── Exchange Rate ───────────────────────────────────────────────
class MockExchangeRate {
  static const rate = 78.50;
  static const source = 'BCV';
  static const lastUpdate = '23 Mar 2026, 09:30 AM';

  static double toVes(double usd) => usd * rate;
  static String formatVes(double usd) => 'Bs. ${toVes(usd).toStringAsFixed(2)}';
  static String formatUsd(double usd) => '\$ ${usd.toStringAsFixed(2)}';
}
