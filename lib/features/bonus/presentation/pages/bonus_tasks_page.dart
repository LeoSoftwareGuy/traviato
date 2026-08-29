import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/widgets/add_photo_sheet.dart';
import '../controllers/bonus_tray_controller.dart';
import '../controllers/bonus_tray_state.dart';
import '../mutations/bonus_task_mutations.dart';
import '../widgets/bonus_completed_row.dart';
import '../widgets/bonus_earned_banner.dart';
import '../widgets/bonus_task_popup_sheet.dart';
import '../widgets/bonus_task_tile.dart';
import '../widgets/stretch_offer_card.dart';

class BonusTasksPage extends ConsumerWidget {
  const BonusTasksPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<dynamic>>(completeBonusTaskMutation, (
      previous,
      next,
    ) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    ref.listen<MutationState<dynamic>>(claimStretchTaskMutation, (
      previous,
      next,
    ) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });

    final trayAsync = ref.watch(bonusTrayControllerProvider(tripId));

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopBonusProfile,
          ),
        ),
        child: SafeArea(
          child: trayAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () =>
                  ref.invalidate(bonusTrayControllerProvider(tripId)),
            ),
            data: (state) => _BonusTrayContent(tripId: tripId, state: state),
          ),
        ),
      ),
    );
  }
}

class _BonusTrayContent extends ConsumerWidget {
  const _BonusTrayContent({required this.tripId, required this.state});

  final String tripId;
  final BonusTrayState state;

  Future<void> _openTask(
    BuildContext context,
    WidgetRef ref,
    BonusTrayTask task,
  ) async {
    final wantsCamera = await BonusTaskPopupSheet.show(context, task: task);
    if (wantsCamera != true || !context.mounted) return;

    await AddPhotoSheet.show(
      context,
      tripId: tripId,
      dayDate: task.assignment.dayDate,
      onSaved: (PhotoEntity photo) async {
        try {
          await runCompleteBonusTask(
            ref: ref,
            tripId: tripId,
            assignmentId: task.assignment.id,
            photoId: photo.id,
          );
        } catch (_) {
          return;
        }
        if (!context.mounted) return;
        showStarToast(
          context,
          '✦ +${task.template.points} stars · dare done',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stretchOffer = state.stretchOffer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        _BonusHeader(onBack: () => context.pop()),
        const SizedBox(height: AppSpacing.xl),
        if (state.bothDailiesDone)
          BonusEarnedBanner(starsEarnedToday: state.starsEarnedToday)
        else
          for (final task in state.dailyTasks) ...[
            BonusTaskTile(
              task: task,
              onTap: () => _openTask(context, ref, task),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (state.claimedStretchToday case final claimed?) ...[
          const SizedBox(height: AppSpacing.sm),
          BonusTaskTile(
            task: claimed,
            onTap: () => _openTask(context, ref, claimed),
          ),
        ] else if (stretchOffer != null) ...[
          const SizedBox(height: AppSpacing.base),
          StretchOfferCard(
            template: stretchOffer,
            onClaim: () async {
              try {
                await runClaimStretchTask(
                  ref: ref,
                  tripId: tripId,
                  dayDate: state.today,
                  templateId: stretchOffer.id,
                );
              } catch (_) {
                return;
              }
            },
          ),
        ],
        if (state.activeStreakSaver case final streakSaver?) ...[
          const SizedBox(height: AppSpacing.base),
          Text(
            'NO RUSH · WAITS FOR YOU',
            style: AppTypography.mono.copyWith(color: AppColors.accentCoral),
          ),
          const SizedBox(height: AppSpacing.sm),
          BonusTaskTile(
            task: streakSaver,
            onTap: () => _openTask(context, ref, streakSaver),
          ),
        ],
        if (state.completedHistory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'COMPLETED',
            style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final task in state.completedHistory)
            BonusCompletedRow(
              task: task,
              dayIndex: state.dayIndexFor(task.assignment.dayDate),
            ),
        ],
      ],
    );
  }
}

class _BonusHeader extends StatelessWidget {
  const _BonusHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: AppRadius.badgeRadius,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'BONUS TASKS',
              style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}
