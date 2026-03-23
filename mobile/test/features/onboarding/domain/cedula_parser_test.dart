import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';

void main() {
  group('CedulaParser', () {
    test('parses V-type cédula with dots', () {
      const text = 'REPUBLICA BOLIVARIANA DE VENEZUELA\nV-12.345.678\nJUAN PEDRO\nGARCIA LOPEZ\n15/03/1985\nSEXO M\nVENEZOLANO';
      final result = CedulaParser.parse(text, []);
      expect(result.idType, 'V');
      expect(result.idNumber, '12345678');
    });

    test('parses E-type cédula (extranjero)', () {
      const text = 'CEDULA DE IDENTIDAD\nE-8.765.432\nMARIA\nRODRIGUEZ\n22/07/1990\nFEMENINO';
      final result = CedulaParser.parse(text, []);
      expect(result.idType, 'E');
      expect(result.idNumber, '8765432');
    });

    test('parses date of birth correctly', () {
      const text = 'V 9876543 CARLOS PEREZ 01/12/1975 MASCULINO VENEZOLANO';
      final result = CedulaParser.parse(text, []);
      expect(result.dateOfBirth, isNotNull);
      expect(result.dateOfBirth!.year, 1975);
      expect(result.dateOfBirth!.month, 12);
    });

    test('parses nationality VENEZOLANO', () {
      const text = 'V-5000001 ANA GOMEZ VENEZOLANA';
      final result = CedulaParser.parse(text, []);
      expect(result.nationality, 'VENEZOLANO');
    });

    test('parses sex MASCULINO', () {
      const text = 'V-6543210 LUIS MARTINEZ MASCULINO';
      final result = CedulaParser.parse(text, []);
      expect(result.sex, 'M');
    });

    test('parses sex FEMENINO', () {
      const text = 'V-7654321 CARMEN SUAREZ FEMENINO';
      final result = CedulaParser.parse(text, []);
      expect(result.sex, 'F');
    });

    test('handles cédula with dots as separators', () {
      const text = 'V-15.123.456 JOSE RODRIGUEZ';
      final result = CedulaParser.parse(text, []);
      expect(result.idType, 'V');
      expect(result.idNumber, isNotNull);
    });

    test('returns empty result for garbage text', () {
      const text = 'LOREM IPSUM DOLOR SIT AMET 1234';
      final result = CedulaParser.parse(text, []);
      expect(result.idNumber, isNull);
    });

    test('confidence is 0 for empty text', () {
      final result = CedulaParser.parse('', []);
      expect(result.confidence, 0.0);
    });

    test('more fields extracted when text is richer', () {
      const fullText = 'V-12345678 PEDRO JOSE GARCIA LOPEZ 15/06/1985 MASCULINO VENEZOLANO';
      const partialText = 'V-12345678';
      final fullResult = CedulaParser.parse(fullText, []);
      final partialResult = CedulaParser.parse(partialText, []);
      expect(fullResult.fieldConfidences.length,
          greaterThan(partialResult.fieldConfidences.length));
    });

    test('handles accented characters in nationality', () {
      const text = 'V-11223344 JOSE EXTRANJERO';
      final result = CedulaParser.parse(text, []);
      expect(result.nationality, 'EXTRANJERO');
    });

    // --- Colombian CC ---

    test('parses Colombian CC with 4-group number (1.127.577.617)', () {
      const text = 'REPÚBLICA DE COLOMBIA\nIDENTIFICACIÓN PERSONAL\n'
          'CÉDULA DE CIUDADANÍA\nNUMERO 1.127.577.617\n'
          'MOLANO ROA\nAPELLIDOS\nDIEGO ALEJANDRO\nNOMBRES';
      final result = CedulaParser.parse(text, []);
      expect(result.idType, 'CC');
      expect(result.idNumber, '1127577617');
      expect(result.idNumber!.length, 10);
    });

    test('parses Colombian CC with 3-group number (12.345.678)', () {
      const text = 'COLOMBIA CEDULA\n12.345.678\nAPELLIDOS\nGOMEZ';
      final result = CedulaParser.parse(text, []);
      expect(result.idType, 'CC');
      expect(result.idNumber, '12345678');
    });

    test('parses Colombian CC date with month name (11-DIC-2003)', () {
      const text = 'COLOMBIA CEDULA 1127577617\nFECHA DE NACIMIENTO 11-DIC-2003';
      final result = CedulaParser.parse(text, []);
      expect(result.dateOfBirth, isNotNull);
      expect(result.dateOfBirth!.year, 2003);
      expect(result.dateOfBirth!.month, 12);
      expect(result.dateOfBirth!.day, 11);
    });

    test('parses Venezuelan cédula V 21.174.873 with space separator', () {
      const text = 'REPUBLICA BOLIVARIANA DE VENEZUELA\n'
          'HURTADO LOPEZ\nEVELIN JOSEFINA\nV 21.174.873\n'
          '14/06/1989\nSOLTERA\nVENEZOLANO';
      final result = CedulaParser.parse(text, []);
      expect(result.idType, 'V');
      expect(result.idNumber, '21174873');
      expect(result.dateOfBirth, isNotNull);
      expect(result.dateOfBirth!.year, 1989);
      expect(result.dateOfBirth!.month, 6);
      expect(result.dateOfBirth!.day, 14);
      expect(result.nationality, 'VENEZOLANO');
    });

    test('excludes accented header lines from name candidates', () {
      // "REPÚBLICA" and "IDENTIFICACIÓN" should be excluded despite accents
      const text = 'REPÚBLICA DE COLOMBIA\nIDENTIFICACIÓN PERSONAL\n'
          'CÉDULA DE CIUDADANÍA\n1127577617';
      final result = CedulaParser.parse(text, []);
      // Should NOT pick up header text as names
      expect(result.firstName, isNot('Republica De Colombia'));
      expect(result.lastName, isNot('Identificación Personal'));
    });
  });
}
