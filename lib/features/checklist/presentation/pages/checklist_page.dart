import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../domain/entities/checklist_item_entity.dart';
import '../controllers/checklist_controller.dart';
import '../controllers/checklist_state.dart';
import '../mutations/checklist_mutations.dart';
import '../widgets/add_checklist_item_input.dart';
import '../widgets/category_tabs.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/checklist_progress_bar.dart';

class ChecklistPage extends ConsumerWidget {
  const ChecklistPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<dynamic>>(toggleChecklistItemMutation, (
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
    ref.listen<MutationState<dynamic>>(addChecklistItemMutation, (
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

    final checklistAsync = ref.watch(checklistControllerProvider(tripId));

    return Scaffold(
      body: SafeArea(
        child: checklistAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error),
            onRetry: () => ref.invalidate(checklistControllerProvider(tripId)),
          ),
          data: (state) => _ChecklistContent(tripId: tripId, state: state),
        ),
      ),
    );
  }
}

class _ChecklistContent extends ConsumerWidget {
  const _ChecklistContent({required this.tripId, required this.state});

  final String tripId;
  final ChecklistState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(checklistControllerProvider(tripId).notifier);
    final itemsForCategory = state.itemsForSelectedCategory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        _ChecklistHeader(onBack: () => context.pop()),
        const SizedBox(height: AppSpacing.xl),
        ChecklistProgressBar(
          checkedCount: state.checkedCount,
          totalCount: state.totalCount,
          progressPercent: state.progressPercent,
        ),
        const SizedBox(height: AppSpacing.base),
        CategoryTabs(
          selected: state.selectedCategory,
          countFor: state.countFor,
          checkedCountFor: state.checkedCountFor,
          onSelect: notifier.selectCategory,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          state.selectedCategory.displayName,
          style: AppTypography.headlineSerif.copyWith(fontSize: 17),
        ),
        const SizedBox(height: AppSpacing.md),
        if (itemsForCategory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'No items in this category yet.',
              style: AppTypography.chipLabel,
            ),
          )
        else
          for (final item in itemsForCategory) ...[
            _ToggleableItemTile(tripId: tripId, item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.md),
        AddChecklistItemInput(
          onSubmit: (title) => runAddChecklistItem(
            ref: ref,
            tripId: tripId,
            category: state.selectedCategory,
            title: title,
          ),
        ),
      ],
    );
  }
}

class _ChecklistHeader extends StatelessWidget {
  const _ChecklistHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: Text(
            'Checklist',
            textAlign: TextAlign.center,
            style: AppTypography.headlineSerif,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ToggleableItemTile extends ConsumerWidget {
  const _ToggleableItemTile({required this.tripId, required this.item});

  final String tripId;
  final ChecklistItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggleState = ref.watch(toggleChecklistItemMutation(item.id));
    return ChecklistItemTile(
      item: item,
      isToggling: toggleState is MutationPending,
      onToggle: () =>
          runToggleChecklistItem(ref: ref, tripId: tripId, item: item),
    );
  }
}
