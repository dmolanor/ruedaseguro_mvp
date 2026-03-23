import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/core/utils/hash_utils.dart';

void main() {
  group('HashUtils.sha256Hash', () {
    test('empty bytes produce known hash', () {
      // SHA-256 of empty input is a fixed constant
      const emptyHash =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      expect(HashUtils.sha256Hash(Uint8List(0)), emptyHash);
    });

    test('known string bytes produce correct hash', () {
      // SHA-256('hello') = 2cf24dba...
      const expected =
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
      final bytes = Uint8List.fromList('hello'.codeUnits);
      expect(HashUtils.sha256Hash(bytes), expected);
    });

    test('different inputs produce different hashes', () {
      final a = HashUtils.sha256Hash(Uint8List.fromList('abc'.codeUnits));
      final b = HashUtils.sha256Hash(Uint8List.fromList('def'.codeUnits));
      expect(a, isNot(equals(b)));
    });

    test('same input always produces same hash', () {
      final bytes = Uint8List.fromList('ruedaseguro'.codeUnits);
      expect(HashUtils.sha256Hash(bytes), HashUtils.sha256Hash(bytes));
    });

    test('output is 64 hex characters', () {
      final hash =
          HashUtils.sha256Hash(Uint8List.fromList('test'.codeUnits));
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });
  });

  group('HashUtils.sha256HashString', () {
    test('empty string produces known hash', () {
      const emptyHash =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      expect(HashUtils.sha256HashString(''), emptyHash);
    });

    test('known string produces correct hash', () {
      const expected =
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
      expect(HashUtils.sha256HashString('hello'), expected);
    });

    test('consistent with sha256Hash on utf8 bytes', () {
      final viaString = HashUtils.sha256HashString('RuedaSeguro');
      final viaBytes = HashUtils.sha256Hash(
          Uint8List.fromList('RuedaSeguro'.codeUnits));
      expect(viaString, viaBytes);
    });
  });
}
