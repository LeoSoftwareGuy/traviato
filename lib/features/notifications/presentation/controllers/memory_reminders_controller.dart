import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/notification_providers.dart';
import 'bonus_notifications_lifecycle_controller.dart';

part 'memory_reminders_controller.g.dart';

/// The You → Settings "Memory reminders" toggle (#307). Stored on the
/// device with the rest of the notification prefs.
@riverpod
class MemoryRemindersController extends _$MemoryRemindersController {
  @override
  Future<bool> build() async =>
      (await ref.read(notificationPrefsStoreProvider).load()).remindersEnabled;

  /// Turning on asks for the OS permission if it isn't granted yet; either
  /// way every reminder is re-planned (off cancels them all).
  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final store = ref.read(notificationPrefsStoreProvider);
    await store.save(
      (await store.load()).copyWith(remindersEnabled: enabled),
    );
    if (enabled) {
      final repo = ref.read(bonusNotificationRepositoryProvider);
      final granted = (await repo.hasPermission()).getOrElse((_) => false);
      if (!granted) await repo.requestPermission();
    }
    await ref
        .read(bonusNotificationsLifecycleControllerProvider.notifier)
        .rescheduleAll();
  }
}
