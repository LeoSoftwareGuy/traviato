import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
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
    ref.listen<MutationState<dynamic>>(deleteChecklistItemMutation, (
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
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background50),
        child: SafeArea(
          child: checklistAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () =>
                  ref.invalidate(checklistControllerProvider(tripId)),
            ),
            data: (state) => _ChecklistContent(tripId: tripId, state: state),
          ),
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
        ),
        const SizedBox(height: AppSpacing.base),
        CategoryTabs(
          selected: state.selectedCategory,
          countFor: state.countFor,
          checkedCountFor: state.checkedCountFor,
          onSelect: notifier.selectCategory,
        ),
        const SizedBox(height: AppSpacing.xl),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  'CHECKLIST',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Pack for the trip',
          style: AppTypography.screenTitle.copyWith(fontSize: 26),
        ),
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
    return Dismissible(
      key: Key('checklist-item-dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      confirmDismiss: (_) async {
        try {
          await runDeleteChecklistItem(
            ref: ref,
            tripId: tripId,
            itemId: item.id,
          );
          return true;
        } catch (_) {
          // Error already surfaced via the mutation listener; keep the item.
          return false;
        }
      },
      child: ChecklistItemTile(
        item: item,
        isToggling: toggleState is MutationPending,
        onToggle: () {
          final wasChecked = item.isChecked;
          runToggleChecklistItem(ref: ref, tripId: tripId, item: item);
          if (!wasChecked) showStarToast(context, '✦ Packed — nice');
        },
      ),
    );
  }
}

/// Revealed behind an item as it's dragged left — "swipe to delete".
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.accentCoral,
        borderRadius: AppRadius.badgeRadius,
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.background),
    );
  }
}
