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
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../controllers/expense_list_controller.dart';
import '../controllers/expense_list_state.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/expense_biggest_category_card.dart';
import '../widgets/expense_category_breakdown.dart';
import '../widgets/expense_empty_selection_panel.dart';
import '../widgets/expense_item_tile.dart';
import '../widgets/expense_load_more_row.dart';
import '../widgets/expense_sort_toggle.dart';
import '../widgets/expense_stats_strip.dart';
import '../widgets/expense_summary_tile.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background50),
        child: SafeArea(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () => ref.invalidate(expenseListControllerProvider),
            ),
            data: (state) => _ExpensesContent(state: state),
          ),
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
    final maxTotal = state.maxTotalAmount;
    final selected = state.selectedSummary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        const _ExpensesHeader(),
        if (state.isEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _NoExpensesYet(
            onCreateTap: () => context.pushNamed(RouteNames.createMemory),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
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
              ExpenseSortToggle(
                value: state.sortMode,
                onChanged: notifier.setSortMode,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MEMORIES', style: AppTypography.mono),
              Text(
                '${visible.length} OF ${state.matchingSummaries.length}',
                style: AppTypography.mono,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
          if (state.hasMoreSummaries) ...[
            const SizedBox(height: AppSpacing.xs),
            ExpenseLoadMoreRow(
              label: 'Load 3 more',
              onTap: notifier.loadMoreSummaries,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (selected == null)
            const ExpenseEmptySelectionPanel()
          else
            _SelectedMemoryDetail(state: state, selected: selected),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => AddExpenseSheet.show(
                context,
                trips: state.summaries,
                initialTripId: state.selectedTripId,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExpensesHeader extends StatelessWidget {
  const _ExpensesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('EXPENSES', style: AppTypography.mono),
        // Expenses · Compare isn't built yet (separate milestone) — present
        // but inert, matching "not built" prototype affordances.
        Text(
          'Compare',
          style: AppTypography.chipLabel.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final label = selected.place == null
        ? selected.tripName.toUpperCase()
        : '${selected.tripName} · ${selected.place}'.toUpperCase();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.mono.copyWith(color: AppColors.primary),
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
                perDay: selected.perDay,
                durationDays: selected.durationDays,
              ),
              if (state.biggestCategory case final category?) ...[
                const SizedBox(height: AppSpacing.sm),
                ExpenseBiggestCategoryCard(
                  category: category,
                  amount: state.categoryTotals[category] ?? 0,
                  totalAmount: selected.totalAmount,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text('BY CATEGORY', style: AppTypography.mono),
              const SizedBox(height: AppSpacing.sm),
              ExpenseCategoryBreakdown(totals: state.categoryTotalsSorted),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ALL EXPENSES', style: AppTypography.mono),
                  Text(
                    '${selected.itemCount} ITEMS · '
                    '${_distinctDayCount(state.selectedTripExpenses)} DAYS',
                    style: AppTypography.mono,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.cardRadius,
                child: Column(
                  children: [
                    for (final (index, expense)
                        in state.visibleSelectedExpenses.indexed)
                      ExpenseItemTile(
                        expense: expense,
                        dayNumber: state.dayNumberFor(expense.spentOn),
                        isEven: index.isEven,
                      ),
                  ],
                ),
              ),
              if (state.hasMoreSelectedExpenses) ...[
                const SizedBox(height: AppSpacing.sm),
                ExpenseLoadMoreRow(
                  label:
                      'Load more '
                      '(${(state.selectedTripExpenses?.length ?? 0) - state.visibleExpenseCount} more)',
                  onTap: ref
                      .read(expenseListControllerProvider.notifier)
                      .loadMoreExpenses,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static int _distinctDayCount(List<ExpenseEntity>? expenses) =>
      expenses == null ? 0 : expenses.map((e) => e.spentOn).toSet().length;
}
