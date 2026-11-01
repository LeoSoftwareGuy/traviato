import '../../domain/entities/planned_reminder_entity.dart';

/// Thin platform wrapper interface — kept separate from the repository so
/// the plugin-specific bits (ids, `AndroidScheduleMode`, `tz.TZDateTime`)
/// stay out of the domain-facing repository impl's catch ladder, mirroring
/// the `name_remote_data_source.dart` / `supabase_name_remote_data_source
/// .dart` split (guidelines doc 09) for a local, non-Supabase backend.
abstract interface class BonusNotificationLocalDataSource {
  /// Initializes the plugin, wires the tap callback (including a cold-start
  /// launch tap, delivered once after this resolves), and initializes the
  /// device's IANA timezone for [replaceReminders]/[scheduleArrival].
  Future<void> init({required void Function(String? payload) onTap});

  Future<bool> hasPermission();

  Future<bool> requestPermission();

  /// Cancels every pending memory reminder and schedules [reminders] in
  /// their place (#307). Arrival reminders are left alone.
  Future<void> replaceReminders(List<PlannedReminderEntity> reminders);

  Future<void> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  });

  Future<void> cancelArrival(String tripId);
}
