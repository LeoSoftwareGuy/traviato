import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_providers.dart';

/// Shows the local-notification rationale dialog once, the first time it's
/// called after the user's first completed bonus task (issue #65 AC — "not
/// at install"). Called from `bonus_tasks_page.dart`'s completion success
/// path. A no-op on every call after the first.
class NotificationPermissionPrompt {
  const NotificationPermissionPrompt._();

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final prefsStore = ref.read(notificationPrefsStoreProvider);
    final prefs = await prefsStore.load();
    if (prefs.hasShownPermissionRationale) return;
    await prefsStore.save(
      prefs.copyWith(hasShownPermissionRationale: true),
    );
    if (!context.mounted) return;

    final repo = ref.read(bonusNotificationRepositoryProvider);
    final alreadyGranted = (await repo.hasPermission()).fold(
      (_) => false,
      (granted) => granted,
    );
    if (alreadyGranted) return;
    if (!context.mounted) return;

    final wantsIt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get a gentle nudge for your daily dares?'),
        content: const Text(
          'Trevy can remind you once in the morning and once in the '
          "evening when a bonus task is still open — never more than that, "
          'and easy to turn off later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (wantsIt != true) return;

    await repo.requestPermission();
  }
}
