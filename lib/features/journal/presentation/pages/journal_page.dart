import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
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

class JournalPage extends ConsumerWidget {
  const JournalPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<dynamic>>(upsertNoteMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    ref.listen<MutationState<dynamic>>(deleteNoteMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    // Covers a failed delete of a day's last photo — the viewer has already
    // closed by then, so it can't show the error itself (#165).
    ref.listen<MutationState<void>>(deletePhotoMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
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
            message: presentationFailureMessage(error, context.l10n),
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
            label: context.l10n.nav_home,
            selected: false,
            onTap: () => context.goNamed(RouteNames.home),
          ),
          AppBottomNavBarItem(
            icon: Icons.receipt_long_outlined,
            label: context.l10n.nav_expenses,
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
                  ? context.l10n.journal_quietOne
                  : context.l10n.journal_dayQuietOne(
                      state.currentDayNumber ?? 1,
                    ),
              style: AppTypography.screenTitle.copyWith(fontSize: 26),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${context.l10n.journal_noEntries} · '
              '${context.l10n.journal_questsDone(state.completedQuestCountForDay(currentDay))}',
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
                  : context.l10n.journal_dayTitle(
                      state.currentDayNumber ?? 1,
                      state.trip.name,
                    ),
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
              key: ValueKey(currentDay),
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
  /// §1) and, once the book has closed, saves the edited entry — or deletes
  /// the note when it was cleared (#276). The day's first note earns the
  /// star, shown as a toast on the Journal after the close (§5); deleting
  /// takes it back.
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

    final note = state.currentNote;
    final existing = note?.content.trim() ?? '';
    final dateLabel = L10nDates.dayMonth(
      context.l10n.localeName,
    ).format(day);
    final draft = await Navigator.of(context).push(
      NotePageRoute(
        stamp: state.isSingleDay
            ? dateLabel
            : context.l10n.journal_noteStamp(
                state.currentDayNumber ?? 1,
                dateLabel,
              ),
        title: state.trip.name,
        existingText: existing,
        photoCount: photos.length,
        photo: firstPhoto,
      ),
    );
    if (draft == null || draft == existing || !context.mounted) return;

    // Fire-and-forget: failures surface via the upsertNoteMutation /
    // deleteNoteMutation listeners in JournalPage.
    if (draft.isEmpty) {
      // The note page already confirmed the delete (#276).
      if (note != null) {
        unawaited(
          runDeleteNote(
            ref: ref,
            tripId: tripId,
            dayDate: day,
            noteId: note.id,
          ),
        );
      }
      return;
    }
    unawaited(
      runUpsertNote(ref: ref, tripId: tripId, dayDate: day, content: draft),
    );
    // The toast lands while the save is in flight.
    if (note == null) showStarToast(context, context.l10n.toast_noteSaved);
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
            context.l10n.journal_noDates,
            textAlign: TextAlign.center,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
