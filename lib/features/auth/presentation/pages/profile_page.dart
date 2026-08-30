import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/auth_mutations.dart';

/// Stopgap Profile screen (issue #75) — the full M4-4 design (avatar, stars
/// pill, stats, achievements grid) hasn't landed yet. Just enough to sign
/// out of the app; replace outright once M4-4 ships.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _logout(WidgetRef ref) async {
    // The mutation's own error state (via ref.listen below) already
    // surfaces the failure as a snackbar — this just stops it from also
    // reaching the zone as an unhandled Future error (guidelines doc 06).
    try {
      await runLogout(ref: ref);
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<void>>(logoutMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isLoggingOut = ref.watch(logoutMutation) is MutationPending;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The full profile screen is on its way.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyInput.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: isLoggingOut ? null : () => _logout(ref),
                child: isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
