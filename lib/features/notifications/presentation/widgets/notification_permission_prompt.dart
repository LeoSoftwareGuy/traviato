import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: Text(context.l10n.notif_promptTitle),
        content: Text(context.l10n.notif_promptBody(AppConstants.appName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.photo_notNow),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.photo_allow),
          ),
        ],
      ),
    );
    if (wantsIt != true) return;

    await repo.requestPermission();
  }
}
