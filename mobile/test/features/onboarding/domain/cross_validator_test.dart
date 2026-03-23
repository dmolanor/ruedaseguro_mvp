import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/carnet_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';

CedulaParseResult _cedula({
  String idType = 'V',
  String idNumber = '12345678',
  String firstName = 'Juan',
  String lastName = 'Garcia',
}) {
  return CedulaParseResult(
    idType: idType,
    idNumber: idNumber,
    firstName: firstName,
    lastName: lastName,
    confidence: 0.9,
  );
}

CarnetParseResult _carnet({
  String? ownerName,
  String? ownerCedula,
}) {
  return CarnetParseResult(
    ownerName: ownerName,
    ownerCedula: ownerCedula,
    confidence: 0.9,
  );
}

void main() {
  group('CrossValidator', () {
    test('exact name + CI match returns overall true', () {
      final result = CrossValidator.validate(
        _cedula(idType: 'V', idNumber: '12345678', firstName: 'Juan', lastName: 'Garcia'),
        _carnet(ownerName: 'Juan Garcia', ownerCedula: 'V12345678'),
      );
      expect(result.overallMatch, isTrue);
      expect(result.nameMatch, isTrue);
      expect(result.cedulaMatch, isTrue);
    });

    test('name mismatch returns overall false', () {
      final result = CrossValidator.validate(
        _cedula(firstName: 'Juan', lastName: 'Garcia'),
        _carnet(ownerName: 'Pedro Lopez', ownerCedula: 'V12345678'),
      );
      expect(result.nameMatch, isFalse);
    });

    test('CI mismatch returns overall false', () {
      final result = CrossValidator.validate(
        _cedula(idNumber: '12345678'),
        _carnet(ownerName: 'Juan Garcia', ownerCedula: 'V99999999'),
      );
      expect(result.cedulaMatch, isFalse);
    });

    test('fuzzy match with accents returns true', () {
      final result = CrossValidator.validate(
        _cedula(firstName: 'María', lastName: 'González'),
        _carnet(ownerName: 'Maria Gonzalez'),
      );
      expect(result.nameMatch, isTrue);
    });

    test('skips validation when carnet has no owner data', () {
      final result = CrossValidator.validate(
        _cedula(),
        _carnet(ownerName: null, ownerCedula: null),
      );
      expect(result.skipped, isTrue);
      expect(result.overallMatch, isTrue);
    });

    test('mismatch details are non-null when mismatch found', () {
      final result = CrossValidator.validate(
        _cedula(firstName: 'Juan', lastName: 'Garcia'),
        _carnet(ownerName: 'Carlos Perez', ownerCedula: 'V99999999'),
      );
      expect(result.mismatchDetails, isNotNull);
    });
  });
}
