import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../controllers/expense_list_controller.dart';
import '../controllers/expense_list_state.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/expense_category_breakdown.dart';
import '../widgets/expense_item_tile.dart';
import '../widgets/expense_sort_dropdown.dart';
import '../widgets/expense_stats_strip.dart';
import '../widgets/expense_summary_tile.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error),
            onRetry: () => ref.invalidate(expenseListControllerProvider),
          ),
          data: (state) => _ExpensesContent(state: state),
        ),
      ),
    );
  }
}

class _ExpensesContent extends ConsumerWidget {
  const _ExpensesContent({required this.state});

  final ExpenseListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expenseListControllerProvider.notifier);
    final visible = state.visibleSummaries;
    final maxTotal = state.maxVisibleTotal;
    final selected = state.selectedSummary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        _ExpensesHeader(
          onAddTap: () => AddExpenseSheet.show(
            context,
            trips: state.summaries,
            initialTripId: state.selectedTripId,
          ),
        ),
        if (state.isEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _NoExpensesYet(
            onCreateTap: () => context.pushNamed(RouteNames.createMemory),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Memories', style: AppTypography.chipLabel),
              const _CompareButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: notifier.setSearchQuery,
                  style: AppTypography.bodyInput,
                  decoration: const InputDecoration(
                    hintText: 'Search memories',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExpenseSortDropdown(
                value: state.sortMode,
                onChanged: notifier.setSortMode,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'No memories match your search.',
                style: AppTypography.chipLabel,
              ),
            )
          else
            for (final summary in visible) ...[
              ExpenseSummaryTile(
                summary: summary,
                maxTotal: maxTotal,
                isSelected: summary.tripId == state.selectedTripId,
                onTap: () => notifier.selectTrip(summary.tripId),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _SelectedMemoryDetail(state: state, selected: selected),
          ],
        ],
      ],
    );
  }
}

class _ExpensesHeader extends StatelessWidget {
  const _ExpensesHeader({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your spending',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text('Expenses', style: AppTypography.displaySerif),
            ],
          ),
        ),
        InkWell(
          onTap: onAddTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: AppColors.background, size: 24),
          ),
        ),
      ],
    );
  }
}

/// Compare-memories screen isn't designed yet (issue #29 AC) — rendered
/// disabled rather than hidden, matching its Figma placement.
class _CompareButton extends StatelessWidget {
  const _CompareButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Compare',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoExpensesYet extends StatelessWidget {
  const _NoExpensesYet({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          color: AppColors.textTertiary,
          size: 40,
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'No expenses yet',
          style: AppTypography.headlineSerif,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Add a memory first, then start tracking what you spend on it.',
          textAlign: TextAlign.center,
          style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: onCreateTap,
          child: const Text('Create your first memory'),
        ),
      ],
    );
  }
}

class _SelectedMemoryDetail extends ConsumerWidget {
  const _SelectedMemoryDetail({required this.state, required this.selected});

  final ExpenseListState state;
  final ExpenseSummaryEntity selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected memory',
          style: AppTypography.caption.copyWith(letterSpacing: 0),
        ),
        Text(selected.tripName, style: AppTypography.headlineSerif),
        if (selected.place != null)
          Text(
            selected.place!,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
        const SizedBox(height: AppSpacing.base),
        if (state.isLoadingSelectedTripExpenses)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          ExpenseStatsStrip(
            totalAmount: selected.totalAmount,
            biggestCategory: state.biggestCategory,
            perDay: selected.perDay,
            durationDays: selected.durationDays,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('By category', style: AppTypography.fieldLabel),
          const SizedBox(height: AppSpacing.sm),
          ExpenseCategoryBreakdown(
            totals: state.categoryTotals,
            totalAmount: selected.totalAmount,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Expenses', style: AppTypography.fieldLabel),
          const SizedBox(height: AppSpacing.sm),
          for (final expense in state.visibleSelectedExpenses)
            ExpenseItemTile(expense: expense),
          if (state.hasMoreSelectedExpenses) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: ref
                    .read(expenseListControllerProvider.notifier)
                    .loadMoreExpenses,
                child: Text(
                  'Load more '
                  '(${(state.selectedTripExpenses?.length ?? 0) - state.visibleExpenseCount} more)',
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
