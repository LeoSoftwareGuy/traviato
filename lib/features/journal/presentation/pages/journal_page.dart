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
import '../../../trip/presentation/mutations/trip_mutations.dart';
import '../controllers/journal_controller.dart';
import '../controllers/journal_state.dart';
import '../mutations/journal_mutations.dart';
import '../widgets/day_note_card.dart';
import '../widgets/day_range_hero.dart';
import '../widgets/day_tabs.dart';
import '../widgets/journal_action_buttons.dart';
import '../widgets/journal_header.dart';
import '../widgets/photos_strip.dart';
import '../widgets/to_do_sheet.dart';

class JournalPage extends ConsumerWidget {
  const JournalPage({required this.tripId, super.key});

  final String tripId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Delete this memory?'),
        content: const Text(
          'This removes the memory and everything in it. Stars you already '
          'earned are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentCoral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await runDeleteMemory(ref: ref, tripId: tripId);
    } catch (_) {
      return;
    }
    if (context.mounted) context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<dynamic>>(upsertNoteMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    ref.listen<MutationState<void>>(deleteMemoryMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });

    final journalAsync = ref.watch(journalControllerProvider(tripId));

    return Scaffold(
      body: SafeArea(
        child: journalAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error),
            onRetry: () => ref.invalidate(journalControllerProvider(tripId)),
          ),
          data: (state) => _JournalContent(
            tripId: tripId,
            state: state,
            onBack: () => context.pop(),
            onDelete: () => _confirmDelete(context, ref),
          ),
        ),
      ),
    );
  }
}

class _JournalContent extends ConsumerWidget {
  const _JournalContent({
    required this.tripId,
    required this.state,
    required this.onBack,
    required this.onDelete,
  });

  final String tripId;
  final JournalState state;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(journalControllerProvider(tripId).notifier);
    final isSavingNote = ref.watch(upsertNoteMutation) is MutationPending;
    final currentDay = state.currentDayDate;

    return ListView(
      key: const Key('journal-content-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      children: [
        JournalHeader(
          tripName: state.trip.name,
          stars: 0,
          onBack: onBack,
          onDelete: onDelete,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!state.hasDateRange || currentDay == null)
          const _NoDatesYet()
        else ...[
          DayRangeHero(
            days: state.dayDates,
            selectedDay: currentDay,
            onSelect: notifier.selectDay,
          ),
          const SizedBox(height: AppSpacing.base),
          DayTabs(
            days: state.dayDates,
            selectedDay: currentDay,
            thumbnailForDay: state.thumbnailForDay,
            onSelect: notifier.selectDay,
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${state.currentDayNumber}',
                style: AppTypography.fieldLabel,
              ),
              Text(
                'Journal started',
                style: AppTypography.caption.copyWith(letterSpacing: 0),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!state.isCurrentDayNoteCached)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            )
          else
            DayNoteCard(
              key: ValueKey(currentDay),
              content: state.currentNote?.content ?? '',
              isSaving: isSavingNote,
              onSave: (content) => runUpsertNote(
                ref: ref,
                tripId: tripId,
                dayDate: currentDay,
                content: content,
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          PhotosStrip(
            photos: state.photosForCurrentDay,
            onAddTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo capture is coming soon.')),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          JournalActionButtons(
            onToDoTap: () => ToDoSheet.show(
              context,
              tripId: tripId,
              dayDate: currentDay,
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
            Icons.auto_stories_outlined,
            color: AppColors.textTertiary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Add dates to this memory to start your journal.',
            textAlign: TextAlign.center,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
