import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount) => _inr.format(amount);
}