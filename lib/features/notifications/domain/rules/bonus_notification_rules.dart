/// Pure fire-time rules for the memory reminders (issue #65, reworked in
/// #307 — the per-day plan lives in `MemoryReminderPlan`). No I/O, no
/// `DateTime.now()` — every input is passed in explicitly, mirroring
/// `BonusTrayDraw` (#64) so the whole rule matrix is trivially unit-testable
/// with an injectable clock.
abstract class BonusNotificationRules {
  const BonusNotificationRules._();

  static const morningHour = 9;
  static const eveningHour = 19;

  /// Nothing is scheduled at/after this local hour
  /// (functionality.md §12 — "never after 21:00").
  static const silenceHour = 21;

  /// Whether an arrival-day notification is still worth scheduling —
  /// `false` once the start date is already in the past.
  static bool shouldScheduleArrival({
    required DateTime now,
    required DateTime startDate,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return !start.isBefore(today);
  }

  static DateTime arrivalFireTime(DateTime startDate) =>
      DateTime(startDate.year, startDate.month, startDate.day, morningHour);
}
