import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/core/utils/validators.dart';

void main() {
  group('Validators.isValidCedula', () {
    test('V-type valid', () => expect(Validators.isValidCedula('V-12345678'), isTrue));
    test('E-type valid', () => expect(Validators.isValidCedula('E-8765432'), isTrue));
    test('lowercase v accepted', () => expect(Validators.isValidCedula('v-1234567'), isTrue));
    test('too short invalid', () => expect(Validators.isValidCedula('V-123'), isFalse));
    test('no prefix invalid', () => expect(Validators.isValidCedula('12345678'), isFalse));
    test('null invalid', () => expect(Validators.isValidCedula(null), isFalse));
    test('empty invalid', () => expect(Validators.isValidCedula(''), isFalse));
  });

  group('Validators.isValidPhone', () {
    test('+58 format valid', () =>
        expect(Validators.isValidPhone('+58 4121234567'), isTrue));
    test('04XX format valid', () =>
        expect(Validators.isValidPhone('04121234567'), isTrue));
    test('invalid prefix', () =>
        expect(Validators.isValidPhone('+58 3001234567'), isFalse));
    test('too short', () =>
        expect(Validators.isValidPhone('+58 412123'), isFalse));
    test('null invalid', () =>
        expect(Validators.isValidPhone(null), isFalse));
  });

  group('Validators.isValidPlate', () {
    test('standard format ABC-123-DE', () =>
        expect(Validators.isValidPlate('ABC123DE'), isTrue));
    test('with dashes', () =>
        expect(Validators.isValidPlate('AB-12-CD'), isTrue));
    test('invalid', () => expect(Validators.isValidPlate('12345'), isFalse));
    test('null invalid', () => expect(Validators.isValidPlate(null), isFalse));
  });

  group('Validators.isValidReference', () {
    test('8 digits valid', () =>
        expect(Validators.isValidReference('12345678'), isTrue));
    test('20 digits valid', () =>
        expect(Validators.isValidReference('12345678901234567890'), isTrue));
    test('too short', () =>
        expect(Validators.isValidReference('1234567'), isFalse));
    test('letters invalid', () =>
        expect(Validators.isValidReference('1234567A'), isFalse));
  });

  group('Validators.isValidBankCode', () {
    test('4 digits valid', () =>
        expect(Validators.isValidBankCode('0102'), isTrue));
    test('3 digits invalid', () =>
        expect(Validators.isValidBankCode('010'), isFalse));
    test('letters invalid', () =>
        expect(Validators.isValidBankCode('01A2'), isFalse));
  });

  group('Validators.isValidPassword', () {
    test('8 chars with number valid', () =>
        expect(Validators.isValidPassword('password1'), isTrue));
    test('too short', () =>
        expect(Validators.isValidPassword('pass1'), isFalse));
    test('no number', () =>
        expect(Validators.isValidPassword('passwordonly'), isFalse));
    test('null invalid', () =>
        expect(Validators.isValidPassword(null), isFalse));
  });

  group('Validators.isValidEmail', () {
    test('valid email', () =>
        expect(Validators.isValidEmail('user@example.com'), isTrue));
    test('no at sign', () =>
        expect(Validators.isValidEmail('userexample.com'), isFalse));
    test('null invalid', () =>
        expect(Validators.isValidEmail(null), isFalse));
  });

  group('Validators.isAdult', () {
    test('35 year old is adult', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 35));
      expect(Validators.isAdult(dob), isTrue);
    });
    test('17 year old is not adult', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 17));
      expect(Validators.isAdult(dob), isFalse);
    });
    test('null returns false', () =>
        expect(Validators.isAdult(null), isFalse));
  });
}
