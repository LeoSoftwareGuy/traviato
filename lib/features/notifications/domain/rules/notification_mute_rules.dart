import '../entities/notification_prefs_entity.dart';

/// Pure mute-counter transition (issue #65 AC: "hard mute after 3
/// consecutively ignored"). "Ignored" has no true delivery/read receipt on
/// a local notification, and every schedule call happens reactively during
/// an app open (there's no server to push a future day's notification
/// ahead of time) — so the only client-observable signal is a *gap*: the
/// app was scheduled to nudge on some day, and the very next calendar day
/// passed with the app never being reopened at all (no evaluation ran, so
/// nothing was scheduled for that day either). Each reopen that arrives
/// after such a gap counts as one ignored instance.
abstract class NotificationMuteRules {
  const NotificationMuteRules._();

  static const muteThreshold = 3;

  /// Call once per app-open evaluation, before deciding today's
  /// schedule/cancel calls (today's decisions should see the up-to-date
  /// [NotificationPrefsEntity.isMuted]). Always stamps [today] as the new
  /// `lastAppOpenDate`; leaves `lastNotificationScheduledDate` untouched —
  /// the caller updates that separately once it knows whether anything was
  /// actually scheduled today.
  static NotificationPrefsEntity updateIgnoreStreak({
    required NotificationPrefsEntity prefs,
    required DateTime today,
  }) {
    if (prefs.isMuted) {
      // Sticky: no un-mute condition is specified by the AC.
      return prefs.copyWith(lastAppOpenDate: () => today);
    }

    final lastScheduled = prefs.lastNotificationScheduledDate;
    if (lastScheduled == null) {
      return prefs.copyWith(lastAppOpenDate: () => today);
    }

    // A gap of >= 2 days means the calendar day right after the last
    // schedule passed with zero app opens (had there been one, that day's
    // evaluation would itself have moved `today` forward to it).
    final gapDays = today.difference(lastScheduled).inDays;
    if (gapDays < 2) {
      return prefs.copyWith(ignoreStreak: 0, lastAppOpenDate: () => today);
    }

    final streak = prefs.ignoreStreak + 1;
    return prefs.copyWith(
      ignoreStreak: streak,
      isMuted: streak >= muteThreshold,
      lastAppOpenDate: () => today,
    );
  }
}
