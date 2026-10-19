import 'package:intl/intl.dart';

/// EUR-only MVP (docs/data-model.md) — drops the decimals when the amount
/// is a whole number, matching the Figma "expenses" frame's amounts.
/// [locale] is the UI language (#220): English keeps `€1,234.50`; Russian
/// writes `1 234,50 €`.
String formatEuro(double amount, String locale) {
  final isWhole = amount == amount.roundToDouble();
  return NumberFormat.currency(
    locale: locale,
    symbol: '€',
    decimalDigits: isWhole ? 0 : 2,
  ).format(amount);
}

/// Parses a typed amount, accepting a decimal comma ("12,50") as well as a
/// point, and spaces as thousands separators — RU/ET keyboards type a comma
/// (#220). Returns `null` for anything that isn't a number.
double? parseEuroAmount(String input) {
  final normalized = input
      .trim()
      .replaceAll(RegExp(r'[\s  ]'), '')
      .replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
