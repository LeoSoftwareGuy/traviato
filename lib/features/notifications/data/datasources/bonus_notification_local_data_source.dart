/// Thin platform wrapper interface — kept separate from the repository so
/// the plugin-specific bits (ids, `AndroidScheduleMode`, `tz.TZDateTime`)
/// stay out of the domain-facing repository impl's catch ladder, mirroring
/// the `name_remote_data_source.dart` / `supabase_name_remote_data_source
/// .dart` split (guidelines doc 09) for a local, non-Supabase backend.
abstract interface class BonusNotificationLocalDataSource {
  /// Initializes the plugin, wires the tap callback (including a cold-start
  /// launch tap, delivered once after this resolves), and initializes the
  /// device's IANA timezone for [scheduleMorning]/[scheduleEvening]/
  /// [scheduleArrival].
  Future<void> init({required void Function(String? payload) onTap});

  Future<bool> hasPermission();

  Future<bool> requestPermission();

  Future<void> scheduleMorning({
    required DateTime fireAt,
    required String tripId,
  });

  Future<void> scheduleEvening({
    required DateTime fireAt,
    required String tripId,
  });

  Future<void> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  });

  Future<void> cancelMorning();

  Future<void> cancelEvening();

  Future<void> cancelArrival(String tripId);
}
