import 'package:flutter/material.dart';

import 'app_snackbar.dart';

/// Shows a one-shot error message. Use with `presentationFailureMessage` to
/// surface a `MutationError`/`AsyncError` (guidelines doc 03/06).
void showErrorSnackbar(BuildContext context, {required String message}) {
  showAppSnackbar(context, message, kind: AppSnackbarKind.error);
}
