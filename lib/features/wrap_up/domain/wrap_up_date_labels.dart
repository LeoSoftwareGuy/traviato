import 'package:intl/intl.dart';

final _dayMonth = DateFormat('d MMMM');
final _dayMonthYear = DateFormat('d MMMM y');

/// The Dust frame's date line (#186), formatted from real dates rather than
/// the string baked into the screenplay so it survives a date shift:
///
/// - single day → `12 August 2026`
/// - same month → `12–16 August 2026`
/// - cross-month → `25 February – 1 March 2026`
/// - cross-year → `30 December 2026 – 2 January 2027`
///
/// Returns `null` when neither date is known, so callers can fall back to
/// the stored text.
String? formatWrapUpDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return null;
  if (start == null || end == null) return _dayMonthYear.format(start ?? end!);
  if (_isSameDate(start, end)) return _dayMonthYear.format(start);
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}–${_dayMonthYear.format(end)}';
  }
  if (start.year == end.year) {
    return '${_dayMonth.format(start)} – ${_dayMonthYear.format(end)}';
  }
  return '${_dayMonthYear.format(start)} – ${_dayMonthYear.format(end)}';
}

/// The Invitation's computed first line — "One day." / "Five days." —
/// mirroring `invitationLine1` in the `generate_wrap_up` edge function.
/// Returns `null` without a full date range.
String? wrapUpDayCountLine(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  final count =
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;
  if (count <= 0) return null;
  if (count == 1) return 'One day.';
  final word = count < _numberWords.length ? _numberWords[count] : '$count';
  return '$word days.';
}

const _numberWords = [
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
  'Twenty',
];

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
