import '../entities/notification_prefs_entity.dart';

/// Plain local storage for [NotificationPrefsEntity] — no `Either`, unlike
/// the rest of the app's repositories. This is trivial local bookkeeping
/// (guidelines doc 01's "trivial local feature" carve-out), not something a
/// caller needs a typed [Failure] to react to; the implementation catches
/// internally and falls back to safe defaults rather than throwing.
abstract interface class NotificationPrefsStore {
  Future<NotificationPrefsEntity> load();

  Future<void> save(NotificationPrefsEntity prefs);
}
