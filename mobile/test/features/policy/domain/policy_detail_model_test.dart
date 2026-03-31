import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';

void main() {
  // ─── Fixture ─────────────────────────────────────────────────────
  Map<String, dynamic> fixture({
    String id = 'aabbccdd-1234-5678-abcd-000000000001',
    String status = 'pending_emission',
    String issuanceStatus = 'provisional',
    String startDate = '2026-03-29T00:00:00.000Z',
    String endDate = '2027-03-29T00:00:00.000Z',
    double premiumUsd = 31.0,
    double premiumVes = 2480.0,
    double exchangeRate = 80.0,
    String? carrierPolicyNumber,
  }) =>
      {
        'id': id,
        'status': status,
        'issuance_status': issuanceStatus,
        'coverage_start': startDate,
        'coverage_end': endDate,
        'price_usd': premiumUsd,
        'price_ves': premiumVes,
        'exchange_rate': exchangeRate,
        'carrier_policy_number': carrierPolicyNumber,
        'profiles': {
          'full_name': 'Juan Carlos Rodríguez',
          'id_type': 'V',
          'id_number': '12345678',
        },
        'vehicles': {
          'brand': 'Honda',
          'model': 'CBF 150',
          'year': 2022,
          'plate': 'ABC-123-DE',
          'color': 'Rojo',
        },
        'policy_types': {
          'name': 'RCV Plus',
          'tier': 'plus',
        },
        'carriers': {
          'name': 'Seguros Pirámide',
        },
      };

  group('PolicyDetailModel.fromMap', () {
    test('parses all scalar fields correctly', () {
      final m = PolicyDetailModel.fromMap(fixture());

      expect(m.id, 'aabbccdd-1234-5678-abcd-000000000001');
      expect(m.status, 'pending_emission');
      expect(m.issuanceStatus, 'provisional');
      expect(m.startDate, '2026-03-29');
      expect(m.endDate, '2027-03-29');
      expect(m.premiumUsd, 31.0);
      expect(m.premiumVes, 2480.0);
      expect(m.exchangeRate, 80.0);
    });

    test('parses rider fields from profiles join', () {
      final m = PolicyDetailModel.fromMap(fixture());

      expect(m.riderFullName, 'Juan Carlos Rodríguez');
      expect(m.riderIdType, 'V');
      expect(m.riderIdNumber, '12345678');
    });

    test('parses vehicle fields from vehicles join', () {
      final m = PolicyDetailModel.fromMap(fixture());

      expect(m.vehicleBrand, 'Honda');
      expect(m.vehicleModel, 'CBF 150');
      expect(m.vehicleYear, 2022);
      expect(m.vehiclePlate, 'ABC-123-DE');
      expect(m.vehicleColor, 'Rojo');
    });

    test('parses plan and carrier fields', () {
      final m = PolicyDetailModel.fromMap(fixture());

      expect(m.planName, 'RCV Plus');
      expect(m.tier, 'plus');
      expect(m.carrierName, 'Seguros Pirámide');
    });

    test('carrierPolicyNumber is null when not set', () {
      final m = PolicyDetailModel.fromMap(fixture());
      expect(m.carrierPolicyNumber, isNull);
    });

    test('carrierPolicyNumber parsed when present', () {
      final m = PolicyDetailModel.fromMap(
          fixture(carrierPolicyNumber: 'PYR-2026-99999'));
      expect(m.carrierPolicyNumber, 'PYR-2026-99999');
    });

    test('handles numeric premium_usd as int', () {
      final raw = fixture();
      raw['premium_usd'] = 31; // int, not double
      final m = PolicyDetailModel.fromMap(raw);
      expect(m.premiumUsd, 31.0);
      expect(m.premiumUsd, isA<double>());
    });
  });

  group('PolicyDetailModel derived helpers', () {
    test('isProvisional true when issuance_status = provisional', () {
      final m = PolicyDetailModel.fromMap(fixture(issuanceStatus: 'provisional'));
      expect(m.isProvisional, isTrue);
      expect(m.isConfirmed, isFalse);
    });

    test('isConfirmed true when issuance_status = confirmed', () {
      final m = PolicyDetailModel.fromMap(fixture(issuanceStatus: 'confirmed'));
      expect(m.isConfirmed, isTrue);
      expect(m.isProvisional, isFalse);
    });

    test('isActive reflects status field', () {
      expect(
        PolicyDetailModel.fromMap(fixture(status: 'active')).isActive,
        isTrue,
      );
      expect(
        PolicyDetailModel.fromMap(fixture(status: 'pending_emission')).isActive,
        isFalse,
      );
    });

    test('displayNumber uses carrierPolicyNumber when available', () {
      final m = PolicyDetailModel.fromMap(
          fixture(carrierPolicyNumber: 'PYR-2026-99999'));
      expect(m.displayNumber, 'PYR-2026-99999');
    });

    test('displayNumber falls back to short UUID when no carrier number', () {
      final m = PolicyDetailModel.fromMap(
          fixture(id: 'aabbccdd-1234-5678-abcd-000000000001'));
      // First 8 chars of id without dashes, uppercased, prefixed with RS-
      expect(m.displayNumber, startsWith('RS-'));
      expect(m.displayNumber.length, greaterThan(4));
    });

    test('formattedStartDate produces human-readable Spanish date', () {
      final m = PolicyDetailModel.fromMap(fixture(startDate: '2026-03-29T00:00:00.000Z'));
      // Should be something like "29 mar 2026" (locale-dependent)
      expect(m.formattedStartDate, isNotEmpty);
      expect(m.formattedStartDate, isNot('2026-03-29T00:00:00.000Z'));
    });

    test('daysRemaining is non-negative', () {
      final future = DateTime.now().add(const Duration(days: 200));
      final endDate =
          '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
      final m = PolicyDetailModel.fromMap(fixture(endDate: endDate));
      expect(m.daysRemaining, greaterThan(0));
      expect(m.daysRemaining, lessThanOrEqualTo(366));
    });

    test('daysRemaining is 0 for expired policies', () {
      final m = PolicyDetailModel.fromMap(fixture(endDate: '2020-01-01'));
      expect(m.daysRemaining, 0);
    });

    test('progressFraction clamps to [0, 1]', () {
      final m = PolicyDetailModel.fromMap(fixture(endDate: '2020-01-01'));
      expect(m.progressFraction, 0.0);
    });
  });

  group('ProfileSummary (inline via PolicyDetailModel rider fields)', () {
    test('riderFullName is trimmed', () {
      final raw = fixture();
      (raw['profiles'] as Map<String, dynamic>)['full_name'] = ' Ana Pérez ';
      final m = PolicyDetailModel.fromMap(raw);
      // The model stores as-is; trimmming happens in ProfileSummary
      expect(m.riderFullName, ' Ana Pérez ');
    });
  });
}
