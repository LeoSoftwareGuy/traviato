import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// What a snackbar is saying — decides its colour and how long it stays.
enum AppSnackbarKind { info, error }

/// The one way to show a snackbar in this app (#153). Every message
/// auto-dismisses after its `AppMotion.snackbar*Duration`, so nothing is
/// left sitting on screen until tapped.
///
/// Flutter makes any snackbar with an action persist by default; this
/// overrides that, keeping an action snackbar up only while a screen reader
/// is on (`accessibleNavigation`) — a timed-out button is unreachable for
/// someone navigating by focus. Showing a new message replaces the current
/// one instead of queueing behind it.
void showAppSnackbar(
  BuildContext context,
  String message, {
  AppSnackbarKind kind = AppSnackbarKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  assert(
    (actionLabel == null) == (onAction == null),
    'actionLabel and onAction go together',
  );
  final hasAction = actionLabel != null && onAction != null;
  final duration = hasAction
      ? AppMotion.snackbarActionDuration
      : switch (kind) {
          AppSnackbarKind.info => AppMotion.snackbarInfoDuration,
          AppSnackbarKind.error => AppMotion.snackbarErrorDuration,
        };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        persist: hasAction && MediaQuery.accessibleNavigationOf(context),
        backgroundColor: kind == AppSnackbarKind.error
            ? AppColors.accentCoral
            : null,
        action: hasAction
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.textPrimary,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
