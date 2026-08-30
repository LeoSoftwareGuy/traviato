import 'package:equatable/equatable.dart';

/// Local-only bookkeeping for the bonus notification loop (issue #65) — the
/// "small prefs/store" the AC calls for. Never persisted server-side.
class NotificationPrefsEntity extends Equatable {
  const NotificationPrefsEntity({
    this.ignoreStreak = 0,
    this.isMuted = false,
    this.lastAppOpenDate,
    this.lastNotificationScheduledDate,
    this.hasShownPermissionRationale = false,
  });

  /// Consecutive days a scheduled morning/evening notification went by
  /// without the app being opened (approximation documented on
  /// [NotificationMuteRules] — there is no true delivery/read receipt).
  final int ignoreStreak;

  /// Sticky hard-mute once [ignoreStreak] hits the threshold. No un-mute
  /// condition is specified by the AC, so this never resets itself.
  final bool isMuted;

  /// Calendar date of the most recent app open evaluated so far. Bookkeeping
  /// only — the mute-streak rule (`NotificationMuteRules`) measures the
  /// reopen gap against `lastNotificationScheduledDate` instead, since
  /// every reactive schedule call stamps both dates together on the same
  /// day (see that class's doc comment).
  final DateTime? lastAppOpenDate;

  /// Calendar date the morning/evening loop last actually scheduled a
  /// notification for — the anchor `NotificationMuteRules` measures the
  /// reopen gap against.
  final DateTime? lastNotificationScheduledDate;

  /// Whether the in-app rationale dialog has been shown once already
  /// (shown after the user's first completed bonus task, not at install).
  final bool hasShownPermissionRationale;

  NotificationPrefsEntity copyWith({
    int? ignoreStreak,
    bool? isMuted,
    DateTime? Function()? lastAppOpenDate,
    DateTime? Function()? lastNotificationScheduledDate,
    bool? hasShownPermissionRationale,
  }) => NotificationPrefsEntity(
    ignoreStreak: ignoreStreak ?? this.ignoreStreak,
    isMuted: isMuted ?? this.isMuted,
    lastAppOpenDate: lastAppOpenDate != null
        ? lastAppOpenDate()
        : this.lastAppOpenDate,
    lastNotificationScheduledDate: lastNotificationScheduledDate != null
        ? lastNotificationScheduledDate()
        : this.lastNotificationScheduledDate,
    hasShownPermissionRationale:
        hasShownPermissionRationale ?? this.hasShownPermissionRationale,
  );

  @override
  List<Object?> get props => [
    ignoreStreak,
    isMuted,
    lastAppOpenDate,
    lastNotificationScheduledDate,
    hasShownPermissionRationale,
  ];
}
