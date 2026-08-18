import 'package:intl/intl.dart';

final _monthDayFormat = DateFormat('MMM d');

String tripCountdownLabel(DateTime startDate) {
  final today = DateTime.now();
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final now = DateTime(today.year, today.month, today.day);
  final days = start.difference(now).inDays;
  if (days <= 0) return 'today';
  return 'in ${days}d';
}

String tripDateRangeLabel(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Dates TBD';
  if (start != null && end != null) {
    return '${_monthDayFormat.format(start)} – ${_monthDayFormat.format(end)}';
  }
  return _monthDayFormat.format(start ?? end!);
}
