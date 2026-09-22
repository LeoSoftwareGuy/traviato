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
import '../../../home/domain/entities/profile_stats_entity.dart';
import '../../../home/presentation/controllers/profile_stats_controller.dart';
import '../../../photo/presentation/pages/photo_viewer_page.dart';
import '../../../photo/presentation/widgets/add_photo_sheet.dart';
import '../controllers/journal_controller.dart';
import '../controllers/journal_state.dart';
import '../mutations/journal_mutations.dart';
import '../widgets/day_note_card.dart';
import '../widgets/day_range_hero.dart';
import '../widgets/day_tabs.dart';
import '../widgets/empty_day_nudge.dart';
import '../widgets/journal_action_buttons.dart';
import '../widgets/journal_header.dart';
import '../widgets/photos_strip.dart';
import '../widgets/to_do_sheet.dart';

class JournalPage extends ConsumerWidget {
  const JournalPage({required this.tripId, super.key});

  final String tripId;

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

    final journalAsync = ref.watch(journalControllerProvider(tripId));
    // Transient: a stats-fetch failure shouldn't block the whole Journal
    // screen (guidelines doc 03) — falls back to zero until it resolves,
    // same fallback Home's header uses (#77).
    final stars =
        (ref.watch(profileStatsControllerProvider).value ??
                const ProfileStatsEntity.zero())
            .stars;

    return Scaffold(
      extendBody: true,
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
            stars: stars,
            onBack: () => context.pop(),
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

class _JournalContent extends ConsumerStatefulWidget {
  const _JournalContent({
    required this.tripId,
    required this.state,
    required this.stars,
    required this.onBack,
  });

  final String tripId;
  final JournalState state;
  final int stars;
  final VoidCallback onBack;

  @override
  ConsumerState<_JournalContent> createState() => _JournalContentState();
}

class _JournalContentState extends ConsumerState<_JournalContent> {
  // Set by the empty-day nudge's "Write a note" action so the normal note
  // editor shows in place of the nudge (#140) — reset whenever the day
  // changes, so switching days doesn't carry the override along.
  DateTime? _revealNoteEditorForDay;

  @override
  Widget build(BuildContext context) {
    final tripId = widget.tripId;
    final state = widget.state;
    final notifier = ref.read(journalControllerProvider(tripId).notifier);
    final isSavingNote = ref.watch(upsertNoteMutation) is MutationPending;
    final currentDay = state.currentDayDate;
    final isEmptyDay =
        currentDay != null &&
        !state.isDayLocked(currentDay) &&
        state.isDayEmpty(currentDay) &&
        !_isSameDate(_revealNoteEditorForDay, currentDay);

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
          stars: widget.stars,
          onBack: widget.onBack,
          onStarsTap: () => context.pushNamed(
            RouteNames.tripBonusTasks,
            pathParameters: {'tripId': tripId},
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!state.hasDateRange || currentDay == null)
          const _NoDatesYet()
        else ...[
          DayRangeHero(
            days: state.dayDates,
            selectedDay: currentDay,
            onSelect: notifier.selectDay,
            isDayLocked: state.isDayLocked,
          ),
          const SizedBox(height: AppSpacing.base),
          DayTabs(
            days: state.dayDates,
            selectedDay: currentDay,
            thumbnailForDay: state.thumbnailForDay,
            onSelect: notifier.selectDay,
            isDayLocked: state.isDayLocked,
            isDayEmpty: state.isDayEmpty,
          ),
          const SizedBox(height: AppSpacing.base),
          if (isEmptyDay) ...[
            Text(
              'Day ${state.currentDayNumber} — a quiet one',
              style: AppTypography.screenTitle.copyWith(fontSize: 26),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No photos, no notes yet · '
              '${state.completedQuestCountForDay(currentDay)} quests done',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            EmptyDayNudge(
              dayNumber: state.currentDayNumber ?? 0,
              onAddPhoto: () => AddPhotoSheet.show(
                context,
                tripId: tripId,
                dayDate: currentDay,
              ),
              onWriteNote: () =>
                  setState(() => _revealNoteEditorForDay = currentDay),
            ),
          ] else ...[
            Text(
              'Day ${state.currentDayNumber} — ${state.trip.name}',
              style: AppTypography.screenTitle.copyWith(fontSize: 26),
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
                updatedAt: state.currentNote?.updatedAt,
                isSaving: isSavingNote,
                onSave: (content) {
                  final isFirstNote = state.currentNote == null;
                  runUpsertNote(
                    ref: ref,
                    tripId: tripId,
                    dayDate: currentDay,
                    content: content,
                  );
                  if (isFirstNote && content.trim().isNotEmpty) {
                    showStarToast(context, '✦ +1 star · note logged');
                  }
                },
              ),
            const SizedBox(height: AppSpacing.xl),
            PhotosStrip(
              photos: state.photosForCurrentDay,
              onAddTap: () => AddPhotoSheet.show(
                context,
                tripId: tripId,
                dayDate: currentDay,
              ),
              onPhotoTap: (index) => PhotoViewerPage.show(
                context,
                photos: state.photosForCurrentDay,
                initialIndex: index,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          JournalActionButtons(
            onToDoTap: () => ToDoSheet.show(
              context,
              tripId: tripId,
              dayDate: currentDay,
            ),
            onViewWrapUpTap: () => context.pushNamed(
              RouteNames.tripWrapUp,
              pathParameters: {'tripId': tripId},
            ),
            state: state,
          ),
        ],
      ],
    );
  }
}

bool _isSameDate(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
