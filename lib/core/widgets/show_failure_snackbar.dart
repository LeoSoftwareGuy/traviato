import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/router/route_constants.dart';
import '../errors/failure_message.dart';
import '../errors/failures.dart';
import '../errors/presentation_failure_exception.dart';
import 'app_snackbar.dart';

/// Shows a `MutationError`/`AsyncError` as a one-shot snackbar, routing a
/// plan-limit failure ([FreeTierLimitFailure]/[PhotoLimitFailure]) to an
/// "Upgrade" action pointing at the paywall entry point instead of the
/// plain error message a dead-end failure gets (#139). The 2,000/memory
/// hard ceiling deliberately isn't one of these — it has no [Failure]
/// subtype of its own and falls through to the plain message below.
void showFailureSnackbar(BuildContext context, Object error) {
  final failure = error is PresentationFailureException ? error.failure : null;
  // String literals rather than `PaywallEntryPoint.name` — core/widgets
  // doesn't depend on a feature package (guidelines doc 08). Must stay in
  // sync with the enum in paywall_page.dart.
  final upsellEntry = switch (failure) {
    FreeTierLimitFailure() => 'memoryCap',
    PhotoLimitFailure() => 'photoCap',
    _ => null,
  };
  // The Upgrade action no longer pins the snackbar on screen (#153) — it
  // auto-dismisses like every other message; see `showAppSnackbar`.
  showAppSnackbar(
    context,
    presentationFailureMessage(error),
    kind: AppSnackbarKind.error,
    actionLabel: upsellEntry != null ? 'Upgrade' : null,
    onAction: upsellEntry != null
        ? () => context.pushNamed(
            RouteNames.subscriptionOfferings,
            queryParameters: {'entry': upsellEntry},
          )
        : null,
  );
}
