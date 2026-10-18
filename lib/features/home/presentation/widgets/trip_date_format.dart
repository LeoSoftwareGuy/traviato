import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';

/// "Aug 12" in English (unchanged), the locale's own month-day order
/// elsewhere: "12 авг.", "12. aug" (#220).
DateFormat _monthDayFormat(AppLocalizations l10n) =>
    DateFormat.MMMd(l10n.localeName);

String tripCountdownLabel(AppLocalizations l10n, DateTime startDate) {
  final today = DateTime.now();
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final now = DateTime(today.year, today.month, today.day);
  final days = start.difference(now).inDays;
  if (days <= 0) return l10n.home_countdownToday;
  return l10n.home_countdownInDays(days);
}

String tripDateRangeLabel(
  AppLocalizations l10n,
  DateTime? start,
  DateTime? end,
) {
  if (start == null && end == null) return l10n.home_datesTbd;
  final format = _monthDayFormat(l10n);
  if (start != null && end != null) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return format.format(start);
    }
    return '${format.format(start)} – ${format.format(end)}';
  }
  return format.format(start ?? end!);
}

/// "Day X of Y" for a trip that's currently underway — clamped into range
/// in case of a clock skew. A single-day trip reads "Today" (#186).
String tripDayOfLabel(AppLocalizations l10n, DateTime start, DateTime end) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final total = end.difference(start).inDays + 1;
  if (total <= 1) return l10n.common_today;
  final dayIndex = todayDate.difference(start).inDays + 1;
  return l10n.common_dayOf(dayIndex.clamp(1, total), total);
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
