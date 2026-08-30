import 'package:traviato/features/notifications/domain/entities/notification_prefs_entity.dart';
import 'package:traviato/features/notifications/domain/repositories/notification_prefs_store.dart';

class FakeNotificationPrefsStore implements NotificationPrefsStore {
  NotificationPrefsEntity stored = const NotificationPrefsEntity();
  var saveCallCount = 0;

  @override
  Future<NotificationPrefsEntity> load() async => stored;

  @override
  Future<void> save(NotificationPrefsEntity prefs) async {
    saveCallCount++;
    stored = prefs;
  }
}
