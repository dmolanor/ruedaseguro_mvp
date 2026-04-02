import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
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

CertificadoParseResult _certificado({
  String? ownerName,
  String? ownerCedula,
  String? vehicleType,
}) {
  return CertificadoParseResult(
    ownerName: ownerName,
    ownerCedula: ownerCedula,
    vehicleType: vehicleType,
    confidence: 0.9,
  );
}

void main() {
  group('CrossValidator', () {
    test('exact name + CI match returns overall true', () {
      final result = CrossValidator.validate(
        _cedula(idType: 'V', idNumber: '12345678', firstName: 'Juan', lastName: 'Garcia'),
        _certificado(ownerName: 'Juan Garcia', ownerCedula: 'V12345678'),
      );
      expect(result.overallMatch, isTrue);
      expect(result.nameMatch, isTrue);
      expect(result.cedulaMatch, isTrue);
    });

    test('name mismatch returns overall false', () {
      final result = CrossValidator.validate(
        _cedula(firstName: 'Juan', lastName: 'Garcia'),
        _certificado(ownerName: 'Pedro Lopez', ownerCedula: 'V12345678'),
      );
      expect(result.nameMatch, isFalse);
    });

    test('CI mismatch returns overall false', () {
      final result = CrossValidator.validate(
        _cedula(idNumber: '12345678'),
        _certificado(ownerName: 'Juan Garcia', ownerCedula: 'V99999999'),
      );
      expect(result.cedulaMatch, isFalse);
    });

    test('fuzzy match with accents returns true', () {
      final result = CrossValidator.validate(
        _cedula(firstName: 'María', lastName: 'González'),
        _certificado(ownerName: 'Maria Gonzalez'),
      );
      expect(result.nameMatch, isTrue);
    });

    test('skips validation when certificado has no owner data', () {
      final result = CrossValidator.validate(
        _cedula(),
        _certificado(ownerName: null, ownerCedula: null),
      );
      expect(result.skipped, isTrue);
      expect(result.overallMatch, isTrue);
    });

    test('mismatch details are non-null when mismatch found', () {
      final result = CrossValidator.validate(
        _cedula(firstName: 'Juan', lastName: 'Garcia'),
        _certificado(ownerName: 'Carlos Perez', ownerCedula: 'V99999999'),
      );
      expect(result.mismatchDetails, isNotNull);
    });

    test('vehicleTypeOk is false for non-motorcycle type', () {
      final result = CrossValidator.validate(
        _cedula(),
        _certificado(
          ownerName: 'Juan Garcia',
          ownerCedula: 'V12345678',
          vehicleType: 'AUTOMOVIL',
        ),
      );
      expect(result.vehicleTypeOk, isFalse);
      expect(result.overallMatch, isFalse);
    });

    test('vehicleTypeOk is true for MOTO type', () {
      final result = CrossValidator.validate(
        _cedula(),
        _certificado(
          ownerName: 'Juan Garcia',
          ownerCedula: 'V12345678',
          vehicleType: 'MOTO PARTICULAR',
        ),
      );
      expect(result.vehicleTypeOk, isTrue);
    });

    test('vehicleTypeOk is true when vehicleType is null (unknown)', () {
      final result = CrossValidator.validate(
        _cedula(),
        _certificado(ownerName: 'Juan Garcia', ownerCedula: 'V12345678'),
      );
      expect(result.vehicleTypeOk, isTrue);
    });
  });
}
