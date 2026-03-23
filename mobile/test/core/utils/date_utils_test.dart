import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ruedaseguro/core/utils/date_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('RSDateUtils.toIso8601 / fromIso8601', () {
    test('round-trips a local DateTime via UTC', () {
      final original = DateTime(2025, 6, 15, 10, 30, 0);
      final iso = RSDateUtils.toIso8601(original);
      final restored = RSDateUtils.fromIso8601(iso);
      expect(restored.toUtc(), original.toUtc());
    });

    test('toIso8601 produces UTC string', () {
      final dt = DateTime.utc(2025, 1, 1);
      expect(RSDateUtils.toIso8601(dt), '2025-01-01T00:00:00.000Z');
    });

    test('fromIso8601 parses UTC string correctly', () {
      final dt = RSDateUtils.fromIso8601('2024-03-21T12:00:00.000Z');
      expect(dt.toUtc().year, 2024);
      expect(dt.toUtc().month, 3);
      expect(dt.toUtc().day, 21);
    });
  });

  group('RSDateUtils.formatDisplayDate', () {
    test('formats date in Spanish locale', () {
      final dt = DateTime(2025, 3, 5);
      final formatted = RSDateUtils.formatDisplayDate(dt);
      // "5 mar 2025" — day, abbreviated Spanish month, year
      expect(formatted.contains('2025'), isTrue);
      expect(formatted.contains('5'), isTrue);
    });

    test('different months produce different strings', () {
      final jan = RSDateUtils.formatDisplayDate(DateTime(2025, 1, 1));
      final dec = RSDateUtils.formatDisplayDate(DateTime(2025, 12, 1));
      expect(jan, isNot(equals(dec)));
    });
  });

  group('RSDateUtils.formatDisplayDateTime', () {
    test('includes time component', () {
      final dt = DateTime(2025, 6, 15, 14, 30);
      final formatted = RSDateUtils.formatDisplayDateTime(dt);
      expect(formatted.contains('14:30'), isTrue);
    });

    test('different times produce different strings', () {
      final morning = RSDateUtils.formatDisplayDateTime(DateTime(2025, 1, 1, 8, 0));
      final evening = RSDateUtils.formatDisplayDateTime(DateTime(2025, 1, 1, 20, 0));
      expect(morning, isNot(equals(evening)));
    });
  });

  group('RSDateUtils.isExpired', () {
    test('past date is expired', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(RSDateUtils.isExpired(past), isTrue);
    });

    test('future date is not expired', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(RSDateUtils.isExpired(future), isFalse);
    });
  });

  group('RSDateUtils.daysUntilExpiry', () {
    test('future date has positive days', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(RSDateUtils.daysUntilExpiry(future), greaterThanOrEqualTo(29));
    });

    test('past date has negative days', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      expect(RSDateUtils.daysUntilExpiry(past), lessThan(0));
    });

    test('tomorrow returns approximately 0 or 1', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final days = RSDateUtils.daysUntilExpiry(tomorrow);
      expect(days, inInclusiveRange(0, 1));
    });
  });
}
