import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/router/route_constants.dart';
import '../errors/failure_message.dart';
import '../errors/failures.dart';
import '../errors/presentation_failure_exception.dart';
import '../theme/app_colors.dart';

/// Shows a `MutationError`/`AsyncError` as a one-shot snackbar, routing a
/// plan-limit failure ([FreeTierLimitFailure]/[PhotoLimitFailure]) to an
/// "Upgrade" action pointing at the paywall entry point instead of the
/// plain error message a dead-end failure gets (#139). The 2,000/memory
/// hard ceiling deliberately isn't one of these — it has no [Failure]
/// subtype of its own and falls through to the plain message below.
void showFailureSnackbar(BuildContext context, Object error) {
  final failure = error is PresentationFailureException ? error.failure : null;
  final upsellMessage = switch (failure) {
    FreeTierLimitFailure(:final message) => message,
    PhotoLimitFailure(:final message) => message,
    _ => null,
  };
  if (upsellMessage != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(upsellMessage),
          backgroundColor: AppColors.accentCoral,
          action: SnackBarAction(
            label: 'Upgrade',
            textColor: AppColors.textPrimary,
            onPressed: () =>
                context.pushNamed(RouteNames.subscriptionOfferings),
          ),
        ),
      );
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(presentationFailureMessage(error)),
        backgroundColor: AppColors.accentCoral,
      ),
    );
}
