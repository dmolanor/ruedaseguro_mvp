// Tests for IotPayloadMapper (RS-094)
//
// All methods are pure functions — no mocking required.

import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/policy/data/iot_payload_mapper.dart';

void main() {
  // ── mapPlanTier ─────────────────────────────────────────────────────────────
  group('IotPayloadMapper.mapPlanTier', () {
    test('maps current canonical keys', () {
      expect(IotPayloadMapper.mapPlanTier('rcv_basico'), 'basic');
      expect(
        IotPayloadMapper.mapPlanTier('rcv_accidentes'),
        'comprehensive_plus',
      );
      expect(IotPayloadMapper.mapPlanTier('rcv_ampliada'), 'premium');
    });

    test('maps legacy keys', () {
      expect(IotPayloadMapper.mapPlanTier('basica'), 'basic');
      expect(IotPayloadMapper.mapPlanTier('plus'), 'comprehensive_plus');
      expect(IotPayloadMapper.mapPlanTier('ampliada'), 'premium');
    });

    test('is case-insensitive', () {
      expect(IotPayloadMapper.mapPlanTier('RCV_BASICO'), 'basic');
      expect(IotPayloadMapper.mapPlanTier('PLUS'), 'comprehensive_plus');
    });

    test('returns basic for null', () {
      expect(IotPayloadMapper.mapPlanTier(null), 'basic');
    });

    test('returns basic for unknown tier', () {
      expect(IotPayloadMapper.mapPlanTier('desconocido'), 'basic');
    });
  });

  // ── normalisePlate ──────────────────────────────────────────────────────────
  group('IotPayloadMapper.normalisePlate', () {
    test('strips dashes from standard moto plate', () {
      expect(IotPayloadMapper.normalisePlate('AB-123-CD'), 'AB123CD');
    });

    test('strips spaces', () {
      expect(IotPayloadMapper.normalisePlate('AB 123 CD'), 'AB123CD');
    });

    test('uppercases lowercase letters', () {
      expect(IotPayloadMapper.normalisePlate('ab-123-cd'), 'AB123CD');
    });

    test('already clean plate passes through', () {
      expect(IotPayloadMapper.normalisePlate('AB123CD'), 'AB123CD');
    });

    test('all-digit plate (numeric-only) passes through', () {
      expect(IotPayloadMapper.normalisePlate('1234567'), '1234567');
    });
  });

  // ── mapPaymentMethod ────────────────────────────────────────────────────────
  group('IotPayloadMapper.mapPaymentMethod', () {
    test('maps pago_movil_p2p', () {
      expect(IotPayloadMapper.mapPaymentMethod('pago_movil_p2p'), 'pago_movil');
    });

    test('maps bank_transfer', () {
      expect(
        IotPayloadMapper.mapPaymentMethod('bank_transfer'),
        'transferencia',
      );
    });

    test('maps debito_inmediato', () {
      expect(
        IotPayloadMapper.mapPaymentMethod('debito_inmediato'),
        'debito_inmediato',
      );
    });

    test('passes through unknown value unchanged', () {
      expect(IotPayloadMapper.mapPaymentMethod('efectivo'), 'efectivo');
    });

    test('returns pago_movil for null', () {
      expect(IotPayloadMapper.mapPaymentMethod(null), 'pago_movil');
    });
  });

  // ── formatNationalId ────────────────────────────────────────────────────────
  group('IotPayloadMapper.formatNationalId', () {
    test('formats V type correctly', () {
      expect(IotPayloadMapper.formatNationalId('V', '12345678'), 'V-12345678');
    });

    test('formats E type correctly', () {
      expect(IotPayloadMapper.formatNationalId('E', '87654321'), 'E-87654321');
    });

    test('strips non-digit characters from number', () {
      expect(
        IotPayloadMapper.formatNationalId('V', 'V-12.345.678'),
        'V-12345678',
      );
    });

    test('lowercases type gets uppercased', () {
      expect(IotPayloadMapper.formatNationalId('v', '12345678'), 'V-12345678');
    });

    test('null type defaults to V', () {
      expect(IotPayloadMapper.formatNationalId(null, '12345678'), 'V-12345678');
    });

    test('null number gives empty string after dash', () {
      expect(IotPayloadMapper.formatNationalId('V', null), 'V-');
    });
  });

  // ── formatDate ──────────────────────────────────────────────────────────────
  group('IotPayloadMapper.formatDate', () {
    test('formats date as YYYY-MM-DD', () {
      expect(IotPayloadMapper.formatDate(DateTime(1990, 5, 3)), '1990-05-03');
    });

    test('pads single-digit month and day', () {
      expect(IotPayloadMapper.formatDate(DateTime(2000, 1, 9)), '2000-01-09');
    });

    test('returns empty string for null', () {
      expect(IotPayloadMapper.formatDate(null), '');
    });

    test('handles end-of-year date', () {
      expect(IotPayloadMapper.formatDate(DateTime(2025, 12, 31)), '2025-12-31');
    });
  });

  // ── toE164Venezuela ─────────────────────────────────────────────────────────
  group('IotPayloadMapper.toE164Venezuela', () {
    test('converts 0414 prefix to E.164', () {
      expect(IotPayloadMapper.toE164Venezuela('04141234567'), '+584141234567');
    });

    test('strips dashes before converting', () {
      expect(
        IotPayloadMapper.toE164Venezuela('0414-123-4567'),
        '+584141234567',
      );
    });

    test('strips spaces before converting', () {
      expect(
        IotPayloadMapper.toE164Venezuela('0414 123 4567'),
        '+584141234567',
      );
    });

    test('leaves already-E.164 number intact', () {
      expect(
        IotPayloadMapper.toE164Venezuela('+584141234567'),
        '+584141234567',
      );
    });

    test('handles 58-prefixed number without leading +', () {
      expect(IotPayloadMapper.toE164Venezuela('584141234567'), '+584141234567');
    });

    test('returns empty string for null', () {
      expect(IotPayloadMapper.toE164Venezuela(null), '');
    });

    test('returns empty string for empty string', () {
      expect(IotPayloadMapper.toE164Venezuela(''), '');
    });

    test('works with 0412 movilnet prefix', () {
      expect(IotPayloadMapper.toE164Venezuela('04129876543'), '+584129876543');
    });
  });

  // ── buildRiderData ──────────────────────────────────────────────────────────
  group('IotPayloadMapper.buildRiderData', () {
    test('constructs rider with all fields', () {
      final rider = IotPayloadMapper.buildRiderData(
        firstName: 'Juan',
        lastName: 'Pérez',
        idType: 'V',
        idNumber: '12345678',
        dob: DateTime(1985, 6, 15),
        email: 'juan@example.com',
        phone: '04141234567',
      );

      expect(rider.firstName, 'Juan');
      expect(rider.lastName, 'Pérez');
      expect(rider.nationalId, 'V-12345678');
      expect(rider.dob, '1985-06-15');
      expect(rider.email, 'juan@example.com');
      expect(rider.phone, '+584141234567');
    });

    test('substitutes empty strings for null fields', () {
      final rider = IotPayloadMapper.buildRiderData(
        firstName: null,
        lastName: null,
        idType: null,
        idNumber: null,
        dob: null,
        email: null,
        phone: null,
      );

      expect(rider.firstName, '');
      expect(rider.lastName, '');
      expect(rider.nationalId, 'V-');
      expect(rider.dob, '');
      expect(rider.email, '');
      expect(rider.phone, '');
    });
  });

  // ── buildAssetData ──────────────────────────────────────────────────────────
  group('IotPayloadMapper.buildAssetData', () {
    test('normalises plate and sets vehicleType to motorbike', () {
      final asset = IotPayloadMapper.buildAssetData(
        plate: 'AB-123-CD',
        brand: 'Honda',
        model: 'CB125',
        year: 2022,
        serialNiv: 'NIV12345',
      );

      expect(asset.vehicleType, 'motorbike');
      expect(asset.licensePlate, 'AB123CD');
      expect(asset.make, 'Honda');
      expect(asset.model, 'CB125');
      expect(asset.year, 2022);
      expect(asset.vin, 'NIV12345');
    });
  });

  // ── buildCoverageData ───────────────────────────────────────────────────────
  group('IotPayloadMapper.buildCoverageData', () {
    test('maps plan tier and stores premium amount', () {
      final cov = IotPayloadMapper.buildCoverageData(
        planTier: 'rcv_ampliada',
        premiumAmount: 18.50,
      );

      expect(cov.planTier, 'premium');
      expect(cov.premiumAmount, 18.50);
    });
  });

  // ── buildPaymentData ────────────────────────────────────────────────────────
  group('IotPayloadMapper.buildPaymentData', () {
    test('converts phone to E.164 and formats date', () {
      final pay = IotPayloadMapper.buildPaymentData(
        method: 'pago_movil_p2p',
        bankCode: '0102',
        sourcePhone: '04141234567',
        reference: 'REF-001',
        paymentDate: DateTime(2026, 4, 7),
      );

      expect(pay.method, 'pago_movil');
      expect(pay.bankCode, '0102');
      expect(pay.sourcePhone, '+584141234567');
      expect(pay.paymentReference, 'REF-001');
      expect(pay.paymentDate, '2026-04-07');
    });
  });
}
