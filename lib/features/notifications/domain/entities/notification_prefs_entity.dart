import 'package:equatable/equatable.dart';

/// Local-only bookkeeping for the memory reminders (issues #65, #307).
/// Never persisted server-side.
class NotificationPrefsEntity extends Equatable {
  const NotificationPrefsEntity({
    this.remindersEnabled = true,
    this.hasShownPermissionRationale = false,
  });

  /// The You → Settings "Memory reminders" toggle (#307). Off cancels every
  /// pending reminder, arrival ones included.
  final bool remindersEnabled;

  /// Whether the in-app rationale dialog has been shown once already
  /// (shown after the first memory is created, not at install — #307).
  final bool hasShownPermissionRationale;

  NotificationPrefsEntity copyWith({
    bool? remindersEnabled,
    bool? hasShownPermissionRationale,
  }) => NotificationPrefsEntity(
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    hasShownPermissionRationale:
        hasShownPermissionRationale ?? this.hasShownPermissionRationale,
  );

  @override
  List<Object?> get props => [remindersEnabled, hasShownPermissionRationale];
}
