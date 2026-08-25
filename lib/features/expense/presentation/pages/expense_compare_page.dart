import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../controllers/expense_compare_controller.dart';
import '../controllers/expense_compare_state.dart';
import '../widgets/expense_compare_table.dart';
import '../widgets/expense_compare_verdict_card.dart';
import '../widgets/expense_summary_tile.dart';

/// "Put two memories' spending side by side." `docs/design/README.md` § 9.
class ExpenseComparePage extends ConsumerWidget {
  const ExpenseComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compareAsync = ref.watch(expenseCompareControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background50),
        child: SafeArea(
          child: compareAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () => ref.invalidate(expenseCompareControllerProvider),
            ),
            data: (state) => _CompareContent(state: state),
          ),
        ),
      ),
    );
  }
}

class _CompareContent extends ConsumerWidget {
  const _CompareContent({required this.state});

  final ExpenseCompareState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expenseCompareControllerProvider.notifier);
    final a = state.summaryA;
    final b = state.summaryB;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        _CompareHeader(
          hasSelection: state.hasAnySelection,
          onBack: () => context.pop(),
          onDoneComparing: notifier.clearSelection,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Which trip cost', style: AppTypography.screenTitle),
        Text(
          'what, really?',
          style: AppTypography.screenTitle.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          state.hintLine,
          style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (state.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Create at least two memories to compare their spending.',
              style: AppTypography.chipLabel,
            ),
          )
        else
          for (final summary in state.summaries) ...[
            ExpenseSummaryTile(
              summary: summary,
              maxTotal: state.summaries
                  .map((s) => s.totalAmount)
                  .fold(0.0, (max, v) => v > max ? v : max),
              isSelected:
                  summary.tripId == state.tripAId ||
                  summary.tripId == state.tripBId,
              accentColor: summary.tripId == state.tripBId
                  ? AppColors.accentPurple
                  : AppColors.primary,
              onTap: () => notifier.selectTrip(summary.tripId),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (state.pairReady && a != null && b != null) ...[
          const SizedBox(height: AppSpacing.xl),
          if (state.isLoadingPair)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            ExpenseCompareTable(state: state, a: a, b: b),
            const SizedBox(height: AppSpacing.base),
            ExpenseCompareVerdictCard(a: a, b: b),
          ],
        ],
      ],
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader({
    required this.hasSelection,
    required this.onBack,
    required this.onDoneComparing,
  });

  final bool hasSelection;
  final VoidCallback onBack;
  final VoidCallback onDoneComparing;

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
              'COMPARE',
              style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ),
        if (hasSelection)
          InkWell(
            onTap: onDoneComparing,
            borderRadius: AppRadius.pillRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentCoralTint,
                border: Border.all(
                  color: AppColors.tint(AppColors.accentCoral, .35),
                ),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                '✕ Done comparing',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.accentCoral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Pick two',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
