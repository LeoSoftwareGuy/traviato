import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_prefs_entity.dart';

const _keyRemindersEnabled = 'notif_reminders_enabled';
const _keyRationaleShown = 'notif_rationale_shown';

/// The ignore-streak mute from #65, replaced by the plan's own back-off in
/// #307. Cleared on save so a sticky mute doesn't linger in storage.
const _legacyKeys = [
  'notif_ignore_streak',
  'notif_is_muted',
  'notif_last_app_open_date',
  'notif_last_scheduled_date',
];

/// Scalar reads/writes backed by `shared_preferences`.
class NotificationPrefsSharedPrefsDataSource {
  Future<NotificationPrefsEntity> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPrefsEntity(
      remindersEnabled: prefs.getBool(_keyRemindersEnabled) ?? true,
      hasShownPermissionRationale: prefs.getBool(_keyRationaleShown) ?? false,
    );
  }

  Future<void> save(NotificationPrefsEntity value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemindersEnabled, value.remindersEnabled);
    await prefs.setBool(
      _keyRationaleShown,
      value.hasShownPermissionRationale,
    );
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }
  }
}
