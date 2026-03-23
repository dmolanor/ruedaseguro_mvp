import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils.formatUSD', () {
    test('formats zero', () => expect(CurrencyUtils.formatUSD(0), '\$0.00'));
    test('formats positive amount',
        () => expect(CurrencyUtils.formatUSD(5.00), '\$5.00'));
    test('formats large amount with commas',
        () => expect(CurrencyUtils.formatUSD(1234.56), '\$1,234.56'));
    test('always shows 2 decimal places',
        () => expect(CurrencyUtils.formatUSD(10.1), '\$10.10'));
  });

  group('CurrencyUtils.formatVES', () {
    test('formats zero', () => expect(CurrencyUtils.formatVES(0), 'Bs. 0.00'));
    test('formats positive amount',
        () => expect(CurrencyUtils.formatVES(180.00), 'Bs. 180.00'));
    test('formats large amount',
        () => expect(CurrencyUtils.formatVES(1234567.89), 'Bs. 1,234,567.89'));
  });

  group('CurrencyUtils.convertUsdToVes', () {
    test('converts at a given rate',
        () => expect(CurrencyUtils.convertUsdToVes(1.0, 36.5), 36.5));
    test('converts larger amount',
        () => expect(CurrencyUtils.convertUsdToVes(10.0, 36.5), 365.0));
    test('zero USD returns zero',
        () => expect(CurrencyUtils.convertUsdToVes(0, 36.5), 0.0));
    test('zero rate returns zero',
        () => expect(CurrencyUtils.convertUsdToVes(5.0, 0), 0.0));
  });

  group('CurrencyUtils.formatExchangeRate', () {
    test('formats rate with label', () {
      expect(CurrencyUtils.formatExchangeRate(36.50), '1 USD = 36.50 Bs.');
    });
    test('formats rate with thousands separator', () {
      expect(
          CurrencyUtils.formatExchangeRate(1234.56), '1 USD = 1,234.56 Bs.');
    });
  });
}
