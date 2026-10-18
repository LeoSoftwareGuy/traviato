import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';

/// "22–26 AUG 2026" (or "22 AUG – 03 SEP 2026" across a month boundary) —
/// the mono date range on the Plan cover banner.
String tripDateRangeMono(
  AppLocalizations l10n,
  DateTime? start,
  DateTime? end,
) {
  if (start == null && end == null) return l10n.home_datesTbd.toUpperCase();
  final locale = l10n.localeName;
  final dayFormat = DateFormat('d', locale);
  final monthFormat = DateFormat('MMM', locale);
  final yearFormat = DateFormat('y', locale);
  if (start != null && end != null) {
    if (start.month == end.month && start.year == end.year) {
      return '${dayFormat.format(start)}–${dayFormat.format(end)} '
          '${monthFormat.format(end).toUpperCase()} ${yearFormat.format(end)}';
    }
    return '${dayFormat.format(start)} ${monthFormat.format(start).toUpperCase()}'
        ' – ${dayFormat.format(end)} ${monthFormat.format(end).toUpperCase()} '
        '${yearFormat.format(end)}';
  }
  final d = start ?? end!;
  return '${dayFormat.format(d)} ${monthFormat.format(d).toUpperCase()} '
      '${yearFormat.format(d)}';
}
