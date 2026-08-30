import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/notifications/domain/rules/bonus_notification_rules.dart';

void main() {
  group('morningFireTime', () {
    test('schedules 9am today when there was activity yesterday', () {
      final now = DateTime(2026, 8, 10, 7, 30);
      final fireAt = BonusNotificationRules.morningFireTime(
        now: now,
        yesterdayHadActivity: true,
        isMuted: false,
      );
      expect(fireAt, DateTime(2026, 8, 10, 9));
    });

    test('skips when there was no activity yesterday', () {
      final fireAt = BonusNotificationRules.morningFireTime(
        now: DateTime(2026, 8, 10, 7, 30),
        yesterdayHadActivity: false,
        isMuted: false,
      );
      expect(fireAt, isNull);
    });

    test('skips when muted, even with activity', () {
      final fireAt = BonusNotificationRules.morningFireTime(
        now: DateTime(2026, 8, 10, 7, 30),
        yesterdayHadActivity: true,
        isMuted: true,
      );
      expect(fireAt, isNull);
    });

    test('skips once 9am has already passed today', () {
      final fireAt = BonusNotificationRules.morningFireTime(
        now: DateTime(2026, 8, 10, 9, 0, 1),
        yesterdayHadActivity: true,
        isMuted: false,
      );
      expect(fireAt, isNull);
    });
  });

  group('eveningFireTime', () {
    test('schedules 7pm today when something is undone', () {
      final fireAt = BonusNotificationRules.eveningFireTime(
        now: DateTime(2026, 8, 10, 12),
        taskUndone: true,
        isMuted: false,
      );
      expect(fireAt, DateTime(2026, 8, 10, 19));
    });

    test('skips when nothing is undone (tray complete)', () {
      final fireAt = BonusNotificationRules.eveningFireTime(
        now: DateTime(2026, 8, 10, 12),
        taskUndone: false,
        isMuted: false,
      );
      expect(fireAt, isNull);
    });

    test('skips when muted', () {
      final fireAt = BonusNotificationRules.eveningFireTime(
        now: DateTime(2026, 8, 10, 12),
        taskUndone: true,
        isMuted: true,
      );
      expect(fireAt, isNull);
    });

    test(
      'fires promptly when evaluated between 7pm and the 9pm cutoff',
      () {
        final now = DateTime(2026, 8, 10, 20, 15);
        final fireAt = BonusNotificationRules.eveningFireTime(
          now: now,
          taskUndone: true,
          isMuted: false,
        );
        expect(fireAt, isNotNull);
        expect(fireAt!.isAfter(now), isTrue);
        expect(fireAt.isBefore(now.add(const Duration(minutes: 5))), isTrue);
      },
    );

    test('never schedules at or after the 9pm silence cutoff', () {
      final fireAt = BonusNotificationRules.eveningFireTime(
        now: DateTime(2026, 8, 10, 21),
        taskUndone: true,
        isMuted: false,
      );
      expect(fireAt, isNull);
    });
  });

  group('arrival', () {
    test('schedules for a start date today or in the future', () {
      expect(
        BonusNotificationRules.shouldScheduleArrival(
          now: DateTime(2026, 8, 10, 15),
          startDate: DateTime(2026, 8, 10),
        ),
        isTrue,
      );
      expect(
        BonusNotificationRules.shouldScheduleArrival(
          now: DateTime(2026, 8, 10),
          startDate: DateTime(2026, 8, 20),
        ),
        isTrue,
      );
    });

    test('skips a start date already in the past', () {
      expect(
        BonusNotificationRules.shouldScheduleArrival(
          now: DateTime(2026, 8, 10),
          startDate: DateTime(2026, 8, 9),
        ),
        isFalse,
      );
    });

    test('arrivalFireTime targets 9am on the start date', () {
      expect(
        BonusNotificationRules.arrivalFireTime(DateTime(2026, 8, 20)),
        DateTime(2026, 8, 20, 9),
      );
    });
  });
}
