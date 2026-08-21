import 'package:intl/intl.dart';

final _wholeEuro = NumberFormat.currency(symbol: '€', decimalDigits: 0);
final _fractionalEuro = NumberFormat.currency(symbol: '€', decimalDigits: 2);

/// EUR-only MVP (docs/data-model.md) — drops the decimals when the amount
/// is a whole number, matching the Figma "expenses" frame's amounts.
String formatEuro(double amount) => amount == amount.roundToDouble()
    ? _wholeEuro.format(amount)
    : _fractionalEuro.format(amount);
