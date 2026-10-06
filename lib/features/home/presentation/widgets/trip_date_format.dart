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
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return _monthDayFormat.format(start);
    }
    return '${_monthDayFormat.format(start)} – ${_monthDayFormat.format(end)}';
  }
  return _monthDayFormat.format(start ?? end!);
}

/// "Day X of Y" for a trip that's currently underway — clamped into range
/// in case of a clock skew. A single-day trip reads "Today" (#186).
String tripDayOfLabel(DateTime start, DateTime end) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final total = end.difference(start).inDays + 1;
  if (total <= 1) return 'Today';
  final dayIndex = todayDate.difference(start).inDays + 1;
  return 'Day ${dayIndex.clamp(1, total)} of $total';
}

/// 0–1 fraction through a current trip, for the hero progress bar.
double tripProgressFraction(DateTime start, DateTime end) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final total = end.difference(start).inDays + 1;
  if (total <= 0) return 0;
  final dayIndex = todayDate.difference(start).inDays + 1;
  return (dayIndex.clamp(1, total)) / total;
}
