import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';

class PolicyTypeModel {
  const PolicyTypeModel({
    required this.id,
    required this.carrierId,
    required this.code,
    required this.name,
    this.description,
    required this.tier,
    required this.priceUsd,
    required this.coverageAmountUsd,
    required this.durationDays,
    required this.paymentFrequency,
    required this.coverageDetails,
    this.isRecommended = false,
    this.targetPercentage,
    required this.isActive,
    this.carrierName,
  });

  final String id; // UUID (policy_types.id)
  final String carrierId; // UUID (carriers.id)
  final String code; // e.g. 'RCV_BASICA'
  final String name; // e.g. 'Solo RCV'
  final String? description;
  final String tier; // 'basica' | 'plus' | 'ampliada'
  final double priceUsd;
  final double coverageAmountUsd;
  final int durationDays;
  final String paymentFrequency;
  final Map<String, dynamic> coverageDetails;
  final bool isRecommended;
  final double? targetPercentage;
  final bool isActive;
  final String? carrierName;

  factory PolicyTypeModel.fromMap(Map<String, dynamic> map) {
    final carrier = map['carriers'] as Map<String, dynamic>?;
    return PolicyTypeModel(
      id: map['id'] as String,
      carrierId: map['carrier_id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      tier: map['tier'] as String? ?? 'basica',
      priceUsd: (map['price_usd'] as num).toDouble(),
      coverageAmountUsd: (map['coverage_amount_usd'] as num? ?? 0).toDouble(),
      durationDays: map['duration_days'] as int? ?? 365,
      paymentFrequency: map['payment_frequency'] as String? ?? 'annual',
      coverageDetails: (map['coverage_details'] as Map<String, dynamic>?) ?? {},
      isRecommended: map['is_recommended'] as bool? ?? false,
      targetPercentage: (map['target_percentage'] as num?)?.toDouble(),
      isActive: map['is_active'] as bool? ?? true,
      carrierName: carrier?['name'] as String?,
    );
  }

  InsurancePlan toInsurancePlan() {
    return InsurancePlan(
      id: id,
      tier: tier,
      policyTypeId: id,
      carrierId: carrierId,
      carrierName: carrierName,
      name: name,
      shortName: _shortName,
      priceUsd: priceUsd,
      targetMarket: _targetMarket,
      coverages: _coverageStrings,
      excluded: _excludedStrings,
      coverageItems: _coverageItems,
      isRecommended: isRecommended,
      accentColor: _accentColor,
      icon: _icon,
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────

  String get _shortName {
    switch (tier) {
      case 'basica':
        return 'Básica';
      case 'plus':
        return 'Plus';
      case 'ampliada':
        return 'Ampliada';
      default:
        return name;
    }
  }

  String get _targetMarket {
    if (targetPercentage != null) {
      return '${targetPercentage!.toStringAsFixed(0)}% del mercado';
    }
    switch (tier) {
      case 'basica':
        return '70% del mercado';
      case 'plus':
        return '30% del mercado';
      case 'ampliada':
        return '5% del mercado';
      default:
        return '';
    }
  }

  List<String> get _coverageStrings {
    final items = <String>[];
    final d = coverageDetails;
    if (d['danos_cosas'] != null) {
      items.add(
        'Daños a cosas de terceros hasta ${_usd(d['danos_cosas'] as num)}',
      );
    }
    if (d['danos_personas'] != null) {
      items.add(
        'Daños a personas de terceros hasta ${_usd(d['danos_personas'] as num)}',
      );
    }
    if (d['defensa_legal'] == true) items.add('Asistencia legal');
    if (d['grua'] == true) items.add('Grúa 24/7');
    if (d['asistencia_medica'] == true) {
      items.add('Asistencia médica inmediata (Venemergencia)');
    }
    if (d['accidentes_personales'] == true) {
      items.add('Accidentes personales 24/7');
    }
    return items;
  }

  List<String> get _excludedStrings {
    final d = coverageDetails;
    return [
      if (d['grua'] != true) 'Sin grúa',
      if (d['asistencia_medica'] != true) 'Sin asistencia médica',
    ];
  }

  List<CoverageItem> get _coverageItems {
    final d = coverageDetails;
    return [
      CoverageItem(
        'Daños a cosas de terceros',
        d['danos_cosas'] != null
            ? _usd(d['danos_cosas'] as num)
            : 'No incluido',
      ),
      CoverageItem(
        'Daños a personas de terceros',
        d['danos_personas'] != null
            ? _usd(d['danos_personas'] as num)
            : 'No incluido',
      ),
      CoverageItem(
        'Asistencia legal',
        d['defensa_legal'] == true ? 'Incluida' : 'No incluido',
      ),
      CoverageItem('Grúa 24/7', d['grua'] == true ? 'Incluida' : 'No incluido'),
      CoverageItem(
        'Asistencia médica (Venemergencia)',
        d['asistencia_medica'] == true ? 'Incluida' : 'No incluido',
      ),
      if (tier == 'plus' || tier == 'ampliada')
        CoverageItem(
          'Accidentes personales 24/7',
          d['accidentes_personales'] == true ? 'Incluida' : 'No incluido',
        ),
    ];
  }

  Color get _accentColor {
    switch (tier) {
      case 'basica':
        return const Color(0xFF5C6BC0);
      case 'plus':
        return const Color(0xFFFF6A1A);
      case 'ampliada':
        return const Color(0xFF0A1B2A);
      default:
        return const Color(0xFF5C6BC0);
    }
  }

  IconData get _icon {
    switch (tier) {
      case 'basica':
        return Icons.shield_outlined;
      case 'plus':
        return Icons.verified_user_rounded;
      case 'ampliada':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  static String _usd(num amount) {
    final fmt = NumberFormat('#,##0', 'en_US');
    return '\$ ${fmt.format(amount)} USD';
  }
}
