import '../entities/planned_reminder_entity.dart';
import 'bonus_notification_rules.dart';

/// Pure planner for a memory's reminders (#307). Reminders used to be
/// scheduled for *today* only, from an app open — so a day the app was
/// never opened was always silent. Instead, every evaluation schedules the
/// next [windowDays] days ahead, and today's entries are adjusted to what
/// was actually logged. No I/O, no `DateTime.now()`, like
/// [BonusNotificationRules].
abstract class MemoryReminderPlan {
  const MemoryReminderPlan._();

  /// How far ahead reminders are scheduled. Two a day stays well under
  /// iOS's 64 pending local notifications.
  static const windowDays = 14;

  /// Days, counting today, that get both reminders. After three days
  /// without the app being opened, only the evening one is left (the last
  /// day and after-end reminders always stay). Opening the app plans again,
  /// so this resets by itself — no sticky mute.
  static const fullDays = 4;

  static const lastDayEveningHour = 18;
  static const afterEndHour = 10;

  /// The reminders for one memory from [now] on, earliest first. Empty when
  /// the memory hasn't started (its arrival reminder covers day one) or
  /// ended more than a day ago. Times already past are dropped.
  static List<PlannedReminderEntity> build({
    required DateTime now,
    required String tripId,
    required String tripName,
    required DateTime startDate,
    required DateTime endDate,
    required bool isKeptForever,
    required bool loggedToday,
    required bool trayDoneToday,
  }) {
    final today = _dateOnly(now);
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final dayAfterEnd = _addDays(end, 1);
    if (today.isBefore(start) || today.isAfter(dayAfterEnd)) return const [];

    final windowEnd = _addDays(today, windowDays - 1);
    final reminders = <PlannedReminderEntity>[];

    PlannedReminderEntity reminder(
      ReminderKind kind,
      DateTime day,
      int hour, {
      int? dayNumber,
    }) => PlannedReminderEntity(
      kind: kind,
      fireAt: DateTime(day.year, day.month, day.day, hour),
      tripId: tripId,
      tripName: tripName,
      dayNumber: dayNumber,
    );

    for (
      var day = today;
      !day.isAfter(windowEnd) && !day.isAfter(dayAfterEnd);
      day = _addDays(day, 1)
    ) {
      if (day == dayAfterEnd) {
        if (!isKeptForever) {
          reminders.add(reminder(ReminderKind.afterEnd, day, afterEndHour));
        }
        continue;
      }

      final dayNumber = _daysBetween(start, day) + 1;
      final isLastDay = day == end;
      final isToday = day == today;

      // Day one's morning is the memory's arrival reminder.
      if (day != start && (isLastDay || _daysBetween(today, day) < fullDays)) {
        reminders.add(
          reminder(
            isLastDay ? ReminderKind.lastDayMorning : ReminderKind.dayMorning,
            day,
            BonusNotificationRules.morningHour,
            dayNumber: dayNumber,
          ),
        );
      }

      if (isToday && loggedToday && trayDoneToday) continue;
      final ReminderKind eveningKind;
      if (isLastDay) {
        eveningKind = ReminderKind.lastDayEvening;
      } else if (isToday && loggedToday) {
        eveningKind = ReminderKind.eveningDareOpen;
      } else {
        eveningKind = ReminderKind.eveningNothingLogged;
      }
      reminders.add(
        reminder(
          eveningKind,
          day,
          isLastDay ? lastDayEveningHour : BonusNotificationRules.eveningHour,
          dayNumber: dayNumber,
        ),
      );
    }

    return [
      for (final r in reminders)
        if (r.fireAt.isAfter(now) &&
            r.fireAt.hour < BonusNotificationRules.silenceHour)
          r,
    ];
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Calendar days from [a] to [b], immune to DST-shortened days.
int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
