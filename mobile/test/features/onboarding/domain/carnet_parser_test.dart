import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/carnet_parser.dart';

void main() {
  group('CarnetParser', () {
    test('parses standard plate format', () {
      const text = 'CARNET DE CIRCULACION\nABC-123-DE\nHONDA\n2019\nROJO';
      final result = CarnetParser.parse(text, []);
      expect(result.plate, isNotNull);
      expect(result.plate!.contains('ABC'), isTrue);
    });

    test('parses plate with spaces', () {
      const text = 'AA 123 BB YAMAHA 2020';
      final result = CarnetParser.parse(text, []);
      expect(result.plate, isNotNull);
    });

    test('parses known brand HONDA', () {
      const text = 'HONDA CB 190 2021 AZUL PARTICULAR';
      final result = CarnetParser.parse(text, []);
      expect(result.brand, 'Honda');
    });

    test('parses known brand BERA', () {
      const text = 'BERA BT250 2018 NEGRO';
      final result = CarnetParser.parse(text, []);
      expect(result.brand, 'Bera');
    });

    test('parses year', () {
      const text = 'YAMAHA FZ 2022 ROJO PARTICULAR';
      final result = CarnetParser.parse(text, []);
      expect(result.year, 2022);
    });

    test('parses color ROJO', () {
      const text = 'KAWASAKI 2020 COLOR ROJO PARTICULAR';
      final result = CarnetParser.parse(text, []);
      expect(result.color, 'Rojo');
    });

    test('parses vehicle use PARTICULAR', () {
      const text = 'HONDA 2021 USO PARTICULAR';
      final result = CarnetParser.parse(text, []);
      expect(result.vehicleUse, 'particular');
    });

    test('parses vehicle use CARGA', () {
      const text = 'BERA 2019 USO CARGA COMERCIAL';
      final result = CarnetParser.parse(text, []);
      expect(result.vehicleUse, 'cargo');
    });

    test('returns empty result for garbage text', () {
      // Avoid known brand substrings (e.g. 'UM' inside 'IPSUM')
      final result = CarnetParser.parse('LOREM DOLOR 99999', []);
      expect(result.plate, isNull);
      expect(result.brand, isNull);
    });

    test('does not confuse year with other numbers', () {
      const text = 'SERIAL 12345678 HONDA 2020 PARTICULAR';
      final result = CarnetParser.parse(text, []);
      expect(result.year, 2020);
    });
  });
}
