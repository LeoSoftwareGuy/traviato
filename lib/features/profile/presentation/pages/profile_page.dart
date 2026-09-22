import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../auth/presentation/mutations/auth_mutations.dart';
import '../../../subscription/presentation/mutations/subscription_mutations.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';
import '../widgets/achievements_grid.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_row.dart';

/// The full Profile screen (issue #96), replacing the auth feature's
/// stopgap (#75) outright.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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
    // Restore purchases (#138) — the full subscription section (design
    // handoff's M6-6) isn't a tracked issue yet, so this is a minimal entry
    // point rather than the styled card that section will eventually add.
    ref.listen<MutationState<dynamic>>(restoreMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      } else if (next is MutationSuccess) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Purchases restored')));
      }
    });

    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopBonusProfile,
          ),
        ),
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () => ref.invalidate(profileControllerProvider),
            ),
            data: (state) => _ProfileContent(state: state),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggingOut = ref.watch(logoutMutation) is MutationPending;
    final isRestoring = ref.watch(restoreMutation) is MutationPending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.base,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        ProfileHeader(
          profile: state.profile,
          stars: state.stats.stars,
          onEdit: () => ProfileEditSheet.show(context),
        ),
        const SizedBox(height: AppSpacing.xl),
        ProfileStatsRow(stats: state.stats),
        const SizedBox(height: AppSpacing.xl),
        AchievementsGrid(achievements: state.achievements),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () =>
                context.pushNamed(RouteNames.subscriptionOfferings),
            child: const Text('Upgrade to Pro'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: isRestoring ? null : () => _restore(ref),
            child: isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Restore purchases'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoggingOut ? null : () => _logout(ref),
            child: isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log out'),
          ),
        ),
      ],
    );
  }

  Future<void> _logout(WidgetRef ref) async {
    // The mutation's own error state (via ref.listen on ProfilePage) already
    // surfaces the failure as a snackbar — this just stops it from also
    // reaching the zone as an unhandled Future error (guidelines doc 06).
    try {
      await runLogout(ref: ref);
    } catch (_) {
      return;
    }
  }

  Future<void> _restore(WidgetRef ref) async {
    // Same reasoning as _logout: the mutation's own error state already
    // surfaces the failure as a snackbar.
    try {
      await runRestore(ref: ref);
    } catch (_) {
      return;
    }
  }
}
