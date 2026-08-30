/// Pure fire-time rules for the bonus notification loop (issue #65). No
/// I/O, no `DateTime.now()` — every input is passed in explicitly, mirroring
/// `BonusTrayDraw` (#64) so the whole rule matrix is trivially unit-testable
/// with an injectable clock.
abstract class BonusNotificationRules {
  const BonusNotificationRules._();

  static const morningHour = 9;
  static const eveningHour = 19;

  /// Nothing is scheduled or prompted at/after this local hour
  /// (functionality.md §12 — "never after 21:00").
  static const silenceHour = 21;

  /// The target fire time for today's morning nudge, or `null` to mean
  /// "cancel any pending one" — muted, no activity yesterday, or 9am has
  /// already passed today (a stale target would fire immediately, which
  /// isn't "~9:00").
  static DateTime? morningFireTime({
    required DateTime now,
    required bool yesterdayHadActivity,
    required bool isMuted,
  }) {
    if (isMuted || !yesterdayHadActivity) return null;
    final target = DateTime(now.year, now.month, now.day, morningHour);
    if (!now.isBefore(target)) return null;
    return target;
  }

  /// The target fire time for today's evening nudge, or `null` to cancel —
  /// muted, nothing undone (includes "tray complete"), or past the 21:00
  /// silence cutoff. If evaluated between 19:00 and the cutoff with
  /// something still undone, fires promptly rather than waiting for a
  /// 19:00 target that has already passed.
  static DateTime? eveningFireTime({
    required DateTime now,
    required bool taskUndone,
    required bool isMuted,
  }) {
    if (isMuted || !taskUndone) return null;
    if (now.hour >= silenceHour) return null;
    final target = DateTime(now.year, now.month, now.day, eveningHour);
    return now.isBefore(target) ? target : now.add(const Duration(minutes: 1));
  }

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
