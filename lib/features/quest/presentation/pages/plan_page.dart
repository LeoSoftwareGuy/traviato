import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../controllers/plan_controller.dart';
import '../controllers/plan_state.dart';
import '../mutations/quest_mutations.dart';
import '../widgets/add_edit_quest_sheet.dart';
import '../widgets/add_quest_row.dart';
import '../widgets/day_navigator.dart';
import '../widgets/manage_memory_sheet.dart';
import '../widgets/plan_header.dart';
import '../widgets/quest_timeline.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({required this.tripId, super.key});

  final String tripId;

  Future<void> _openManageSheet(BuildContext context, WidgetRef ref) async {
    final deleted = await ManageMemorySheet.show(context, tripId: tripId);
    if (deleted == true && context.mounted) {
      context.goNamed(RouteNames.home);
    }
  }

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
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background50),
        child: SafeArea(
          child: planAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () => ref.invalidate(planControllerProvider(tripId)),
            ),
            data: (state) => _PlanContent(
              tripId: tripId,
              state: state,
              onManageTap: () => _openManageSheet(context, ref),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        onFabTap: () => context.pushNamed(RouteNames.createMemory),
        items: [
          AppBottomNavBarItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: false,
            onTap: () => context.goNamed(RouteNames.home),
          ),
          AppBottomNavBarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Expenses',
            selected: false,
            onTap: () => context.goNamed(RouteNames.expenses),
          ),
        ],
      ),
    );
  }
}

class _PlanContent extends ConsumerWidget {
  const _PlanContent({
    required this.tripId,
    required this.state,
    required this.onManageTap,
  });

  final String tripId;
  final PlanState state;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDay = state.questsForCurrentDay;
    final doneCount = currentDay.where((q) => q.isCompleted).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl * 2,
      ),
      children: [
        PlanHeader(
          trip: state.trip,
          currentDayNumber: state.currentDayNumber,
          totalDays: state.totalDays,
          onBack: () => context.pop(),
          onChecklistTap: () => context.pushNamed(
            RouteNames.tripChecklist,
            pathParameters: {'tripId': tripId},
          ),
          onManageTap: onManageTap,
        ),
        const SizedBox(height: AppSpacing.base),
        if (!state.hasDateRange)
          const _NoDatesYet()
        else ...[
          Text(
            '${state.totalQuestsPlanned} quests planned · '
            '${state.totalDays} days total',
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          DayNavigator(
            currentDate: state.currentDayDate!,
            dayNumber: state.currentDayNumber!,
            totalDays: state.totalDays,
            doneCount: doneCount,
            totalForDay: currentDay.length,
            canGoToPreviousDay: state.canGoToPreviousDay,
            canGoToNextDay: state.canGoToNextDay,
            onPreviousDay: () => ref
                .read(planControllerProvider(tripId).notifier)
                .goToPreviousDay(),
            onNextDay: () =>
                ref.read(planControllerProvider(tripId).notifier).goToNextDay(),
            onSelectDayNumber: (day) => ref
                .read(planControllerProvider(tripId).notifier)
                .goToDayNumber(day),
          ),
          const SizedBox(height: AppSpacing.lg),
          QuestTimeline(
            tripId: tripId,
            quests: currentDay,
            onToggle: (quest) {
              final wasCompleted = quest.isCompleted;
              runToggleQuest(ref: ref, tripId: tripId, quest: quest);
              if (!wasCompleted) {
                showStarToast(context, '✦ +1 star · quest done');
              }
            },
            onEditQuest: (quest) => AddEditQuestSheet.show(
              context,
              tripId: tripId,
              dayDate: state.currentDayDate!,
              quest: quest,
            ),
          ),
          if (currentDay.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          AddQuestRow(
            dayNumber: state.currentDayNumber!,
            onTap: () => AddEditQuestSheet.show(
              context,
              tripId: tripId,
              dayDate: state.currentDayDate!,
            ),
          ),
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
