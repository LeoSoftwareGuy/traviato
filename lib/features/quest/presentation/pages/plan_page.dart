import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../controllers/plan_controller.dart';
import '../controllers/plan_state.dart';
import '../mutations/quest_mutations.dart';
import '../widgets/add_edit_quest_sheet.dart';
import '../widgets/day_navigator.dart';
import '../widgets/plan_header.dart';
import '../widgets/quest_timeline.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<dynamic>>(toggleQuestMutation, (
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

    final planAsync = ref.watch(planControllerProvider(tripId));

    return Scaffold(
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error),
            onRetry: () => ref.invalidate(planControllerProvider(tripId)),
          ),
          data: (state) => _PlanContent(tripId: tripId, state: state),
        ),
      ),
    );
  }
}

class _PlanContent extends ConsumerWidget {
  const _PlanContent({required this.tripId, required this.state});

  final String tripId;
  final PlanState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        PlanHeader(
          trip: state.trip,
          onBack: () => context.pop(),
          onChecklistTap: () => context.pushNamed(
            RouteNames.tripChecklist,
            pathParameters: {'tripId': tripId},
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!state.hasDateRange)
          const _NoDatesYet()
        else ...[
          DayNavigator(
            currentDate: state.currentDayDate!,
            dayNumber: state.currentDayNumber!,
            canGoToPreviousDay: state.canGoToPreviousDay,
            canGoToNextDay: state.canGoToNextDay,
            onPreviousDay: () => ref
                .read(planControllerProvider(tripId).notifier)
                .goToPreviousDay(),
            onNextDay: () =>
                ref.read(planControllerProvider(tripId).notifier).goToNextDay(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.totalQuestsPlanned} quests planned',
                style: AppTypography.fieldLabel,
              ),
              Text(
                '${state.totalDays} days total',
                style: AppTypography.caption.copyWith(letterSpacing: 0),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          QuestTimeline(
            tripId: tripId,
            quests: state.questsForCurrentDay,
            onToggle: (quest) =>
                runToggleQuest(ref: ref, tripId: tripId, quest: quest),
            onEditQuest: (quest) => AddEditQuestSheet.show(
              context,
              tripId: tripId,
              dayDate: state.currentDayDate!,
              quest: quest,
            ),
            onAddQuest: () => AddEditQuestSheet.show(
              context,
              tripId: tripId,
              dayDate: state.currentDayDate!,
            ),
          ),
          if (state.questsForCurrentDay.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AddEditQuestSheet.show(
                  context,
                  tripId: tripId,
                  dayDate: state.currentDayDate!,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add plan'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _NoDatesYet extends StatelessWidget {
  const _NoDatesYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            color: AppColors.textTertiary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Add dates to this memory to start planning your days.',
            textAlign: TextAlign.center,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
