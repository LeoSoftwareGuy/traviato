import '../../../core/utils/logical_day.dart';

/// The Journal day a photo's capture time points to, when it isn't the
/// day the user is adding it to (#468) — so the app can ask "This photo
/// was taken on … Add it to … instead?". Null when the photo fits
/// [journalDay] (its capture date, or the night after before the
/// logical-day cutoff), has no capture time, or was taken on no open day
/// of the memory ([start]–[end], never after [today]).
///
/// [captureWallClock]'s fields are the clock where it was taken
/// ([PhotoExif.wallClock]).
DateTime? suggestedPhotoDay({
  required DateTime? captureWallClock,
  required DateTime journalDay,
  required DateTime? start,
  required DateTime? end,
  required DateTime today,
}) {
  final at = captureWallClock;
  if (at == null) return null;
  final day = _date(journalDay);
  final calendar = DateTime(at.year, at.month, at.day);
  final early = at.hour < logicalDayCutoffHour;
  final eveningBefore = calendar.subtract(const Duration(days: 1));
  if (calendar == day || (early && eveningBefore == day)) return null;

  bool open(DateTime d) =>
      (start == null || !d.isBefore(_date(start))) &&
      (end == null || !d.isAfter(_date(end))) &&
      !d.isAfter(_date(today));
  if (open(calendar)) return calendar;
  // Before 08:00 on a day past the memory: the night of its last evening.
  if (early && open(eveningBefore)) return eveningBefore;
  return null;
}

DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);
