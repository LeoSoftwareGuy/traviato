import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../auth/presentation/mutations/auth_mutations.dart';
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
}
