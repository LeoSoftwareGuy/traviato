import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/notifications/domain/entities/notification_prefs_entity.dart';
import 'package:traviato/features/notifications/domain/rules/notification_mute_rules.dart';

void main() {
  test('no-op when nothing was ever scheduled', () {
    const prefs = NotificationPrefsEntity();
    final updated = NotificationMuteRules.updateIgnoreStreak(
      prefs: prefs,
      today: DateTime(2026, 8, 10),
    );
    expect(updated.ignoreStreak, 0);
    expect(updated.isMuted, isFalse);
    expect(updated.lastAppOpenDate, DateTime(2026, 8, 10));
  });

  test('reopening the very next day is not ignored', () {
    final prefs = NotificationPrefsEntity(
      lastNotificationScheduledDate: DateTime(2026, 8, 8),
    );
    final updated = NotificationMuteRules.updateIgnoreStreak(
      prefs: prefs,
      today: DateTime(2026, 8, 9),
    );
    expect(updated.ignoreStreak, 0);
    expect(updated.isMuted, isFalse);
  });

  test(
    'increments the streak when a full day passed with no reopen',
    () {
      final prefs = NotificationPrefsEntity(
        lastNotificationScheduledDate: DateTime(2026, 8, 8),
      );
      final updated = NotificationMuteRules.updateIgnoreStreak(
        prefs: prefs,
        // Skipped the 9th entirely — first reopen is the 10th.
        today: DateTime(2026, 8, 10),
      );
      expect(updated.ignoreStreak, 1);
      expect(updated.isMuted, isFalse);
    },
  );

  test('mutes once the streak reaches the threshold', () {
    final prefs = NotificationPrefsEntity(
      ignoreStreak: 2,
      lastNotificationScheduledDate: DateTime(2026, 8, 8),
    );
    final updated = NotificationMuteRules.updateIgnoreStreak(
      prefs: prefs,
      today: DateTime(2026, 8, 10),
    );
    expect(updated.ignoreStreak, 3);
    expect(updated.isMuted, isTrue);
  });

  test('a same-day re-evaluation does not affect the streak', () {
    final prefs = NotificationPrefsEntity(
      ignoreStreak: 2,
      lastNotificationScheduledDate: DateTime(2026, 8, 8),
    );
    final updated = NotificationMuteRules.updateIgnoreStreak(
      prefs: prefs,
      today: DateTime(2026, 8, 8),
    );
    expect(updated.ignoreStreak, 0);
  });

  test('stays muted with no un-mute path once muted', () {
    final prefs = NotificationPrefsEntity(
      ignoreStreak: 5,
      isMuted: true,
      lastNotificationScheduledDate: DateTime(2026, 1, 1),
      lastAppOpenDate: DateTime(2026, 8, 9),
    );
    final updated = NotificationMuteRules.updateIgnoreStreak(
      prefs: prefs,
      today: DateTime(2026, 8, 20),
    );
    expect(updated.isMuted, isTrue);
    expect(updated.ignoreStreak, 5);
    expect(updated.lastAppOpenDate, DateTime(2026, 8, 20));
  });
}
