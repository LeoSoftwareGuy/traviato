import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_prefs_entity.dart';

const _keyIgnoreStreak = 'notif_ignore_streak';
const _keyIsMuted = 'notif_is_muted';
const _keyLastAppOpenDate = 'notif_last_app_open_date';
const _keyLastScheduledDate = 'notif_last_scheduled_date';
const _keyRationaleShown = 'notif_rationale_shown';

/// Scalar reads/writes backed by `shared_preferences`. Dates are stored as
/// `YYYY-MM-DD` strings (date-only — the entity never carries a time-of-day).
class NotificationPrefsSharedPrefsDataSource {
  Future<NotificationPrefsEntity> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPrefsEntity(
      ignoreStreak: prefs.getInt(_keyIgnoreStreak) ?? 0,
      isMuted: prefs.getBool(_keyIsMuted) ?? false,
      lastAppOpenDate: _parseDate(prefs.getString(_keyLastAppOpenDate)),
      lastNotificationScheduledDate: _parseDate(
        prefs.getString(_keyLastScheduledDate),
      ),
      hasShownPermissionRationale: prefs.getBool(_keyRationaleShown) ?? false,
    );
  }

  Future<void> save(NotificationPrefsEntity value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIgnoreStreak, value.ignoreStreak);
    await prefs.setBool(_keyIsMuted, value.isMuted);
    await _saveDate(prefs, _keyLastAppOpenDate, value.lastAppOpenDate);
    await _saveDate(
      prefs,
      _keyLastScheduledDate,
      value.lastNotificationScheduledDate,
    );
    await prefs.setBool(
      _keyRationaleShown,
      value.hasShownPermissionRationale,
    );
  }

  Future<void> _saveDate(
    SharedPreferences prefs,
    String key,
    DateTime? date,
  ) async {
    if (date == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, _formatDate(date));
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
