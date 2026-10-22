import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/kept_memory.dart';

/// Date and count labels for the Kept Memory page and viewer (#279), in the
/// UI language. Callers uppercase eyebrows themselves.
abstract class KeptMemoryLabels {
  /// `12–16 Aug 2026` · `30 Jul – 2 Aug 2026` · `30 Dec 2026 – 2 Jan 2027`.
  static String dateRange(DateTime start, DateTime end, String locale) {
    final dayMonthYear = DateFormat('d MMM y', locale);
    if (start.year == end.year && start.month == end.month) {
      if (start.day == end.day) return dayMonthYear.format(start);
      return '${start.day}–${dayMonthYear.format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM', locale).format(start)} – '
          '${dayMonthYear.format(end)}';
    }
    return '${dayMonthYear.format(start)} – ${dayMonthYear.format(end)}';
  }

  /// `Tue 12 Aug` — a day chapter's date and the viewer's caption line.
  static String weekdayDate(DateTime date, String locale) =>
      DateFormat('EEE d MMM', locale).format(date);

  /// `17 Aug 2026` — the footer's kept date.
  static String keptDate(DateTime date, String locale) =>
      DateFormat('d MMM y', locale).format(date.toLocal());

  /// `05:48` — a note's time, 24-hour like the design's mono stamps.
  static String noteTime(DateTime time) =>
      DateFormat('HH:mm').format(time.toLocal());

  /// `1:19` — the film's length.
  static String filmDuration(Duration duration) {
    final seconds = duration.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// `5 days · 84 photos · 9 notes · ✦46` — a segment whose count is 0 is
  /// left out.
  static String meta(KeptMemory memory, AppLocalizations l10n) => [
    if (memory.dayCount > 0) l10n.common_dayCount(memory.dayCount),
    if (memory.photoCount > 0) l10n.common_photoCount(memory.photoCount),
    if (memory.noteCount > 0) l10n.keptMemory_noteCount(memory.noteCount),
    if (memory.trip.stars > 0) '✦${memory.trip.stars}',
  ].join(' · ');
}
