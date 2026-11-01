import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/notifications/domain/rules/bonus_notification_rules.dart';

void main() {
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
