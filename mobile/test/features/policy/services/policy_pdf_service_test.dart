import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';
import 'package:ruedaseguro/features/policy/services/policy_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('PolicyPdfService.generateBytes', () {
    test('generates non-empty bytes for demo mode (null policy)', () async {
      final bytes = await PolicyPdfService.generateBytes(null);
      expect(bytes, isNotEmpty);
      // PDF magic bytes: %PDF
      expect(bytes[0], 0x25); // %
      expect(bytes[1], 0x50); // P
      expect(bytes[2], 0x44); // D
      expect(bytes[3], 0x46); // F
    });

    test('generates non-empty bytes for a provisional policy', () async {
      final policy = _makePolicy(isProvisional: true);
      final bytes = await PolicyPdfService.generateBytes(policy);
      expect(bytes, isNotEmpty);
      expect(bytes[0], 0x25);
    });

    test('generates non-empty bytes for a confirmed policy', () async {
      final policy = _makePolicy(isProvisional: false);
      final bytes = await PolicyPdfService.generateBytes(policy);
      expect(bytes, isNotEmpty);
    });

    test('demo PDF and real PDF are different', () async {
      final demoBytes = await PolicyPdfService.generateBytes(null);
      final realBytes = await PolicyPdfService.generateBytes(_makePolicy());
      expect(demoBytes, isNot(equals(realBytes)));
    });
  });
}

PolicyDetailModel _makePolicy({bool isProvisional = true}) {
  return PolicyDetailModel(
    id: 'test-uuid-1234-5678-abcd-000000000001',
    status: isProvisional ? 'pending_emission' : 'active',
    issuanceStatus: isProvisional ? 'provisional' : 'confirmed',
    startDate: '2026-03-29',
    endDate: '2027-03-29',
    premiumUsd: 31.0,
    premiumVes: 2480.0,
    exchangeRate: 80.0,
    riderFullName: 'Juan Carlos Rodríguez',
    riderIdType: 'V',
    riderIdNumber: '12345678',
    vehicleBrand: 'Honda',
    vehicleModel: 'CBF 150',
    vehicleYear: 2022,
    vehiclePlate: 'ABC-123-DE',
    vehicleColor: 'Rojo',
    planName: 'RCV Plus',
    tier: 'plus',
    carrierName: 'Seguros Pirámide',
    carrierPolicyNumber: isProvisional ? null : 'PYR-2026-99999',
  );
}
