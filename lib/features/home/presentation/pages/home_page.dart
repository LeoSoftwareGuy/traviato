import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/mutations/auth_mutations.dart';

/// Placeholder authenticated landing page — replaced by the real Home
/// screen in #7. Proves the auth vertical slice end-to-end (greeting +
/// logout).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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

    final username = ref.watch(authControllerProvider).user?.username;
    final isLoggingOut = ref.watch(logoutMutation) is MutationPending;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, ${username ?? 'traveler'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: isLoggingOut ? null : () => runLogout(ref: ref),
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
      ),
    );
  }
}
