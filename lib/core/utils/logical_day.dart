/// The journal's "logical day" rule (#397), shared by the Journal, stats and
/// the wrap-up film: they all read the `day_date` this decides when an item
/// (a photo or a note) is saved.
///
/// An item with a local time from 00:00 to before 08:00 stays on the
/// previous item's day while there has been no gap of [newDayGap] or more
/// since that item — a night out keeps going. Otherwise, and at any time
/// from 08:00, it belongs to its own calendar date.
library;

/// From this hour on, an item always starts its own calendar day.
const logicalDayCutoffHour = 8;

/// A break this long (or longer) before an early-morning item starts a new
/// day.
const newDayGap = Duration(hours: 4);

/// The day an item at [at] (local time) belongs to, given the trip's latest
/// item before it: [previousAt] and the day it was put on, [previousDay].
/// Returns a date-only [DateTime].
DateTime logicalDayOf(
  DateTime at, {
  DateTime? previousAt,
  DateTime? previousDay,
}) {
  final calendar = _dateOnly(at);
  if (at.hour >= logicalDayCutoffHour) return calendar;
  if (previousAt == null || previousDay == null) return calendar;
  final gap = at.difference(previousAt);
  if (gap.isNegative || gap >= newDayGap) return calendar;
  final day = _dateOnly(previousDay);
  // Only ever the same night: the previous calendar day, or this one.
  final yesterday = DateTime(calendar.year, calendar.month, calendar.day - 1);
  return day == yesterday || day == calendar ? day : calendar;
}

/// Whether [at] falls after midnight of [day] — where the Journal shows its
/// `AFTER MIDNIGHT · <date>` divider.
bool isAfterMidnightOf(DateTime at, DateTime day) =>
    _dateOnly(at).isAfter(_dateOnly(day));

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
