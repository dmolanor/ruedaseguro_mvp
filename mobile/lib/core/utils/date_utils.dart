import 'package:intl/intl.dart';

class RSDateUtils {
  RSDateUtils._();

  static String toIso8601(DateTime dt) => dt.toUtc().toIso8601String();

  static DateTime fromIso8601(String iso) => DateTime.parse(iso);

  static String formatDisplayDate(DateTime dt) =>
      DateFormat('d MMM yyyy', 'es').format(dt);

  static String formatDisplayDateTime(DateTime dt) =>
      DateFormat('d MMM yyyy, HH:mm', 'es').format(dt);

  static bool isExpired(DateTime dt) => dt.isBefore(DateTime.now());

  static int daysUntilExpiry(DateTime dt) =>
      dt.difference(DateTime.now()).inDays;
}
