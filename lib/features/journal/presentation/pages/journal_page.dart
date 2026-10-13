import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../../photo/presentation/mutations/photo_mutations.dart';
import '../../../photo/presentation/pages/photo_viewer_page.dart';
import '../../../photo/presentation/widgets/add_photo_sheet.dart';
import '../../../photo/presentation/widgets/storage_photo_image.dart';
import '../../domain/note_text.dart';
import '../controllers/journal_controller.dart';
import '../controllers/journal_state.dart';
import '../mutations/journal_mutations.dart';
import '../widgets/day_note_card.dart';
import '../widgets/day_range_hero.dart';
import '../widgets/day_tabs.dart';
import '../widgets/empty_day_nudge.dart';
import '../widgets/journal_action_buttons.dart';
import '../widgets/journal_header.dart';
import '../widgets/note_page/note_title_page.dart';
import '../widgets/photos_strip.dart';
import '../widgets/to_do_sheet.dart';
import 'note_page.dart';

final _stampDateFormat = DateFormat('d MMM');

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
    // Covers a failed delete of a day's last photo — the viewer has already
    // closed by then, so it can't show the error itself (#165).
    ref.listen<MutationState<void>>(deletePhotoMutation, (previous, next) {
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

class _JournalContent extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(journalControllerProvider(tripId).notifier);
    final isSavingNote = ref.watch(upsertNoteMutation) is MutationPending;
    final currentDay = state.currentDayDate;
    final isEmptyDay =
        currentDay != null &&
        !state.isDayLocked(currentDay) &&
        state.isDayEmpty(currentDay);

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
          stars: stars,
          onBack: onBack,
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
              state.isSingleDay
                  ? 'A quiet one'
                  : 'Day ${state.currentDayNumber} — a quiet one',
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
              dayNumber: state.isSingleDay ? null : state.currentDayNumber,
              onAddPhoto: () => AddPhotoSheet.show(
                context,
                tripId: tripId,
                dayDate: currentDay,
              ),
              onWriteNote: () => _openNotePage(context, ref, currentDay),
            ),
          ] else ...[
            Text(
              state.isSingleDay
                  ? state.trip.name
                  : 'Day ${state.currentDayNumber} — ${state.trip.name}',
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
                onOpenNotePage: () => _openNotePage(context, ref, currentDay),
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
                onDelete: (photo) =>
                    runDeletePhoto(ref: ref, tripId: tripId, photo: photo),
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

  /// Opens the full-screen note page (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
  /// §1) and, once the book has closed, appends whatever was added to the
  /// day's entry. Star behaviour is unchanged for now: the day's first note
  /// earns the star, shown as a toast on the Journal after the close (§5).
  Future<void> _openNotePage(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
  ) async {
    final photos = state.photosForCurrentDay;
    final firstPhoto = photos.isEmpty ? null : photos.first;
    final url = firstPhoto?.imageUrl;
    if (url != null) {
      // Best effort: the polaroid is usually already cached from the strip;
      // never hold the page back for a slow download.
      await precacheImage(
        StoragePhotoImage.providerFor(
          url: url,
          storagePath: firstPhoto!.storagePath,
          maxDecodeDimension: StoragePhotoImage.maxDecodeDimensionFor(
            notePolaroidPhotoSize,
            MediaQuery.devicePixelRatioOf(context),
          ),
        ),
        context,
      ).timeout(const Duration(milliseconds: 300), onTimeout: () {});
      if (!context.mounted) return;
    }

    final existing = state.currentNote?.content ?? '';
    final dateLabel = _stampDateFormat.format(day);
    final draft = await Navigator.of(context).push(
      NotePageRoute(
        stamp: state.isSingleDay
            ? dateLabel
            : 'Day ${state.currentDayNumber} · $dateLabel',
        title: state.trip.name,
        existingText: existing,
        photoCount: photos.length,
        photo: firstPhoto,
      ),
    );
    if (draft == null || draft.isEmpty || !context.mounted) return;

    final isFirstNote = existing.trim().isEmpty;
    // Fire-and-forget: failures surface via the upsertNoteMutation listener
    // in JournalPage, and the toast lands while the save is in flight.
    unawaited(
      runUpsertNote(
        ref: ref,
        tripId: tripId,
        dayDate: day,
        content: appendNoteText(existing, draft),
      ),
    );
    if (isFirstNote) showStarToast(context, '✦ +1 star · note saved');
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
