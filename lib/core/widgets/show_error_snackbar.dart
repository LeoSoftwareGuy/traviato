import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows a one-shot error message. Use with `presentationFailureMessage` to
/// surface a `MutationError`/`AsyncError` (guidelines doc 03/06).
void showErrorSnackbar(BuildContext context, {required String message}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentCoral,
      ),
    );
}
