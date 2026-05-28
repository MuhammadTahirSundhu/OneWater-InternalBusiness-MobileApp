import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  static final _formatterWithDecimals = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 2,
  );

  /// Format as PKR X,XXX
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Format as PKR X,XXX.XX
  static String formatWithDecimals(num amount) {
    return _formatterWithDecimals.format(amount);
  }

  /// Format compact: PKR 1.5K, PKR 2.3M
  static String formatCompact(num amount) {
    if (amount >= 1000000) {
      return 'PKR ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'PKR ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
