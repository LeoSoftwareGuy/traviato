import 'package:intl/intl.dart';

final _dayFormat = DateFormat('d');
final _monthFormat = DateFormat('MMM');
final _yearFormat = DateFormat('y');

/// "22–26 AUG 2026" (or "22 AUG – 03 SEP 2026" across a month boundary) —
/// the mono date range on the Plan cover banner.
String tripDateRangeMono(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'DATES TBD';
  if (start != null && end != null) {
    if (start.month == end.month && start.year == end.year) {
      return '${_dayFormat.format(start)}–${_dayFormat.format(end)} '
          '${_monthFormat.format(end).toUpperCase()} ${_yearFormat.format(end)}';
    }
    return '${_dayFormat.format(start)} ${_monthFormat.format(start).toUpperCase()}'
        ' – ${_dayFormat.format(end)} ${_monthFormat.format(end).toUpperCase()} '
        '${_yearFormat.format(end)}';
  }
  final d = start ?? end!;
  return '${_dayFormat.format(d)} ${_monthFormat.format(d).toUpperCase()} '
      '${_yearFormat.format(d)}';
}
