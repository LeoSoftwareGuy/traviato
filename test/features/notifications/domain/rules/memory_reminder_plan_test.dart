import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/notifications/domain/entities/planned_reminder_entity.dart';
import 'package:traviato/features/notifications/domain/rules/memory_reminder_plan.dart';

typedef _Slot = (ReminderKind, DateTime);

void main() {
  // A five-day memory, Aug 1–5.
  final start = DateTime(2026, 8, 1);
  final end = DateTime(2026, 8, 5);

  List<PlannedReminderEntity> plan(
    DateTime now, {
    DateTime? startDate,
    DateTime? endDate,
    bool isKeptForever = false,
    bool loggedToday = false,
    bool trayDoneToday = false,
  }) => MemoryReminderPlan.build(
    now: now,
    tripId: 't1',
    tripName: 'Lisbon',
    startDate: startDate ?? start,
    endDate: endDate ?? end,
    isKeptForever: isKeptForever,
    loggedToday: loggedToday,
    trayDoneToday: trayDoneToday,
  );

  List<_Slot> slots(List<PlannedReminderEntity> reminders) => [
    for (final r in reminders) (r.kind, r.fireAt),
  ];

  test('plans the whole memory ahead from day one (#307)', () {
    expect(slots(plan(DateTime(2026, 8, 1, 7))), [
      // Day one's morning is the arrival reminder, scheduled separately.
      (ReminderKind.eveningNothingLogged, DateTime(2026, 8, 1, 19)),
      (ReminderKind.dayMorning, DateTime(2026, 8, 2, 9)),
      (ReminderKind.eveningNothingLogged, DateTime(2026, 8, 2, 19)),
      (ReminderKind.dayMorning, DateTime(2026, 8, 3, 9)),
      (ReminderKind.eveningNothingLogged, DateTime(2026, 8, 3, 19)),
      (ReminderKind.dayMorning, DateTime(2026, 8, 4, 9)),
      (ReminderKind.eveningNothingLogged, DateTime(2026, 8, 4, 19)),
      (ReminderKind.lastDayMorning, DateTime(2026, 8, 5, 9)),
      (ReminderKind.lastDayEvening, DateTime(2026, 8, 5, 18)),
      (ReminderKind.afterEnd, DateTime(2026, 8, 6, 10)),
    ]);
  });

  test('carries the memory name and day number', () {
    final dayThree = plan(
      DateTime(2026, 8, 3, 7),
    ).firstWhere((r) => r.kind == ReminderKind.dayMorning);
    expect(dayThree.dayNumber, 3);
    expect(dayThree.tripName, 'Lisbon');
    expect(dayThree.tripId, 't1');
  });

  test('nothing before the memory starts', () {
    expect(plan(DateTime(2026, 7, 30, 12)), isEmpty);
  });

  group('today', () {
    final noon = DateTime(2026, 8, 3, 12);

    test('a logged day with the tray done gets no evening reminder', () {
      final reminders = plan(noon, loggedToday: true, trayDoneToday: true);
      expect(reminders.first.fireAt, DateTime(2026, 8, 4, 9));
    });

    test('a logged day with a bonus task open gets the dare reminder', () {
      final reminders = plan(noon, loggedToday: true);
      expect(slots(reminders).first, (
        ReminderKind.eveningDareOpen,
        DateTime(2026, 8, 3, 19),
      ));
    });

    test('a done tray alone is not enough — nothing logged yet', () {
      final reminders = plan(noon, trayDoneToday: true);
      expect(reminders.first.kind, ReminderKind.eveningNothingLogged);
    });

    test('times already past today are dropped', () {
      final reminders = plan(DateTime(2026, 8, 3, 19, 30));
      expect(reminders.first.fireAt, DateTime(2026, 8, 4, 9));
    });
  });

  group('last day', () {
    test('evening reminder is at 18:00 even when a dare is open', () {
      final reminders = plan(DateTime(2026, 8, 5, 12), loggedToday: true);
      expect(slots(reminders), [
        (ReminderKind.lastDayEvening, DateTime(2026, 8, 5, 18)),
        (ReminderKind.afterEnd, DateTime(2026, 8, 6, 10)),
      ]);
    });

    test('a fully logged last day only keeps the after-end reminder', () {
      final reminders = plan(
        DateTime(2026, 8, 5, 12),
        loggedToday: true,
        trayDoneToday: true,
      );
      expect(slots(reminders), [
        (ReminderKind.afterEnd, DateTime(2026, 8, 6, 10)),
      ]);
    });

    test('a one-day memory gets its last-day evening and after-end', () {
      expect(
        slots(plan(DateTime(2026, 8, 1, 7), endDate: DateTime(2026, 8, 1))),
        [
          (ReminderKind.lastDayEvening, DateTime(2026, 8, 1, 18)),
          (ReminderKind.afterEnd, DateTime(2026, 8, 2, 10)),
        ],
      );
    });
  });

  group('after the end', () {
    test('the next morning still gets the keep-forever reminder', () {
      expect(slots(plan(DateTime(2026, 8, 6, 8))), [
        (ReminderKind.afterEnd, DateTime(2026, 8, 6, 10)),
      ]);
    });

    test('a kept memory gets none', () {
      expect(plan(DateTime(2026, 8, 6, 8), isKeptForever: true), isEmpty);
    });

    test('two days after the end, nothing', () {
      expect(plan(DateTime(2026, 8, 7, 8)), isEmpty);
    });
  });

  group('a long memory', () {
    final longEnd = DateTime(2026, 8, 31);
    final reminders = plan(DateTime(2026, 8, 10, 10), endDate: longEnd);

    test('is planned 14 days ahead', () {
      expect(reminders.last.fireAt, DateTime(2026, 8, 23, 19));
    });

    test('backs off to evenings only after three unopened days', () {
      final mornings = reminders
          .where((r) => r.kind == ReminderKind.dayMorning)
          .map((r) => r.fireAt);
      expect(mornings, [
        DateTime(2026, 8, 11, 9),
        DateTime(2026, 8, 12, 9),
        DateTime(2026, 8, 13, 9),
      ]);
      final evenings = reminders.where(
        (r) => r.kind == ReminderKind.eveningNothingLogged,
      );
      expect(evenings, hasLength(14));
    });

    test('never at or after 21:00, never more than two a day', () {
      final perDay = <DateTime, int>{};
      for (final r in reminders) {
        expect(r.fireAt.hour, lessThan(21));
        final day = DateTime(r.fireAt.year, r.fireAt.month, r.fireAt.day);
        perDay[day] = (perDay[day] ?? 0) + 1;
      }
      expect(perDay.values.every((n) => n <= 2), isTrue);
    });

    test('the last day keeps its morning beyond the back-off', () {
      final lastDays = plan(
        DateTime(2026, 8, 20, 10),
        endDate: DateTime(2026, 8, 30),
      ).where((r) => r.kind == ReminderKind.lastDayMorning);
      expect(lastDays.single.fireAt, DateTime(2026, 8, 30, 9));
    });
  });

  test('taps on "log your day" reminders open the Journal', () {
    final byKind = {for (final r in plan(DateTime(2026, 8, 1, 7))) r.kind: r};
    expect(byKind[ReminderKind.dayMorning]!.payload, 't1');
    expect(byKind[ReminderKind.eveningNothingLogged]!.payload, 'journal:t1');
    expect(byKind[ReminderKind.afterEnd]!.payload, 'journal:t1');
  });
}
