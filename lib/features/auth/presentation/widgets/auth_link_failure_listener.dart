import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_link_failure_controller.dart';
import '../controllers/auth_state.dart';

/// Shows a friendly snackbar when an email confirmation link fails (#157).
/// Sits in `MaterialApp.router`'s `builder` — above the router's Navigator
/// but inside the app's ScaffoldMessenger — so it catches the failure on
/// whichever screen is up, including the splash on a cold start.
class AuthLinkFailureListener extends ConsumerWidget {
  const AuthLinkFailureListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthLinkFailure?>(authLinkFailureControllerProvider, (
      _,
      failure,
    ) {
      if (failure == null) return;
      ref.read(authLinkFailureControllerProvider.notifier).clear();
      // A signed-in user tapping a stale link only needs the explanation;
      // the "Log in" shortcut is for someone left on the guest screens.
      final isSignedOut =
          ref.read(authControllerProvider).status == AuthStatus.unauthenticated;
      showAppSnackbar(
        context,
        failure.message,
        kind: AppSnackbarKind.error,
        actionLabel: isSignedOut ? 'Log in' : null,
        onAction: isSignedOut
            ? () => ref.read(routerProvider).goNamed(RouteNames.login)
            : null,
      );
    });
    return child;
  }
}
