import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final _usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  static final _vesFormat = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2);
  static final _rateFormat = NumberFormat('#,##0.00');

  static String formatUSD(double amount) => _usdFormat.format(amount);

  static String formatVES(double amount) => _vesFormat.format(amount);

  static double convertUsdToVes(double usd, double rate) => usd * rate;

  static String formatExchangeRate(double rate) =>
      '1 USD = ${_rateFormat.format(rate)} Bs.';
}
