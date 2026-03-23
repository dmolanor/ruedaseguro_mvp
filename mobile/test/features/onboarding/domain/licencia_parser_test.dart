import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/licencia_parser.dart';

void main() {
  group('LicenciaParser', () {
    test('parses holder cédula V-12345678', () {
      const text = 'LICENCIA PARA CONDUCIR\nV-12.345.678\nJUAN PEREZ';
      final result = LicenciaParser.parse(text, []);
      expect(result.holderCedula, 'V12345678');
    });

    test('parses grado categories from text', () {
      const text = 'LICENCIA CONDUCIR\n1° GRADO\n2° GRADO\nV-12345678';
      final result = LicenciaParser.parse(text, []);
      expect(result.categories, containsAll(['1°', '2°']));
      expect(result.authorizedForMotorcycle, isTrue);
    });

    test('parses grado with GRADO keyword format', () {
      const text = 'LICENCIA\nGRADO 1\nGRADO 3\nV-9876543';
      final result = LicenciaParser.parse(text, []);
      expect(result.categories, containsAll(['1°', '3°']));
    });

    test('authorizedForMotorcycle is false without 1° grado', () {
      const text = 'LICENCIA CONDUCIR\n2° GRADO\nV-12345678';
      final result = LicenciaParser.parse(text, []);
      expect(result.authorizedForMotorcycle, isFalse);
    });

    test('parses blood type A+', () {
      const text = 'LICENCIA CONDUCIR\nGRUPO SANGUINEO A+\nV-12345678';
      final result = LicenciaParser.parse(text, []);
      expect(result.bloodType, 'A+');
    });

    test('parses blood type O-', () {
      const text = 'LICENCIA\nGS O-\n1° GRADO';
      final result = LicenciaParser.parse(text, []);
      expect(result.bloodType, 'O-');
    });

    test('parses blood type AB+', () {
      const text = 'LICENCIA CONDUCIR\nSANGRE AB+\nV-5000001';
      final result = LicenciaParser.parse(text, []);
      expect(result.bloodType, 'AB+');
    });

    test('parses expiry date (latest date is chosen)', () {
      // Issue date: 15/03/2020, Expiry date: 15/03/2030
      const text = 'LICENCIA CONDUCIR\nEMISION 15/03/2020\nVENCIMIENTO 15/03/2030';
      final result = LicenciaParser.parse(text, []);
      expect(result.expiryDate, isNotNull);
      expect(result.expiryDate!.year, 2030);
      expect(result.expiryDate!.month, 3);
      expect(result.expiryDate!.day, 15);
    });

    test('parses license number (long numeric string)', () {
      const text = 'LICENCIA CONDUCIR\nNUMERO 123456789\nV-12345678\n1° GRADO';
      final result = LicenciaParser.parse(text, []);
      expect(result.licenciaNumber, isNotNull);
      // Should pick up 123456789 (9 digits), not 12345678 (the cédula)
      expect(result.licenciaNumber, '123456789');
    });

    test('confidence is 0 for empty text', () {
      final result = LicenciaParser.parse('', []);
      expect(result.confidence, 0.0);
    });

    test('returns empty result for garbage text', () {
      const text = 'LOREM IPSUM DOLOR SIT AMET 1234';
      final result = LicenciaParser.parse(text, []);
      expect(result.holderCedula, isNull);
      expect(result.categories, isEmpty);
    });

    test('more fields produce higher confidence', () {
      const fullText = 'LICENCIA PARA CONDUCIR\nV-12345678\n'
          '1° GRADO\n2° GRADO\nGS A+\n'
          'EMISION 01/01/2020\nVENCIMIENTO 01/01/2030\n'
          'NUMERO 987654321';
      const partialText = 'LICENCIA\nV-12345678';
      final fullResult = LicenciaParser.parse(fullText, []);
      final partialResult = LicenciaParser.parse(partialText, []);
      expect(fullResult.fieldConfidences.length,
          greaterThan(partialResult.fieldConfidences.length));
    });

    test('parses all five grados', () {
      const text = 'LICENCIA\n1° 2° 3° 4° 5°\nV-12345678';
      final result = LicenciaParser.parse(text, []);
      expect(result.categories.length, 5);
    });

    test('handles cédula with space separator', () {
      const text = 'LICENCIA CONDUCIR\nV 21174873\n1° GRADO';
      final result = LicenciaParser.parse(text, []);
      expect(result.holderCedula, 'V21174873');
    });
  });
}
