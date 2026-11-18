import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../home/domain/entities/profile_stats_entity.dart';
import '../../../home/presentation/controllers/profile_stats_controller.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/mutations/photo_mutations.dart';
import '../../../photo/presentation/pages/photo_viewer_page.dart';
import '../../../photo/presentation/widgets/add_photo_sheet.dart';
import '../../../wrap_up/presentation/providers/film_pick_providers.dart';
import '../../domain/entities/journal_note_entity.dart';
import '../controllers/journal_controller.dart';
import '../controllers/journal_state.dart';
import '../mutations/journal_mutations.dart';
import '../widgets/day_range_hero.dart';
import '../widgets/day_tabs.dart';
import '../widgets/journal_action_buttons.dart';
import '../widgets/journal_header.dart';
import '../widgets/timeline/day_timeline_view.dart';
import '../widgets/timeline/empty_day_notebook.dart';
import '../widgets/timeline/fold_away.dart';
import '../widgets/timeline/journal_balloon_bar.dart';
import '../widgets/timeline/note_sheets.dart';
import '../widgets/to_do_sheet.dart';
import '../note_composer.dart';

class JournalPage extends ConsumerWidget {
  const JournalPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void showFailure(
      MutationState<dynamic>? previous,
      MutationState<dynamic> next,
    ) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    }

    ref.listen<MutationState<dynamic>>(createNoteMutation, showFailure);
    ref.listen<MutationState<dynamic>>(updateNoteMutation, showFailure);
    ref.listen<MutationState<dynamic>>(deleteNoteMutation, showFailure);
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
      body: journalAsync.when(
        loading: () => const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => SafeArea(
          child: AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error, context.l10n),
            onRetry: () => ref.invalidate(journalControllerProvider(tripId)),
          ),
        ),
        data: (state) => _JournalContent(
          tripId: tripId,
          state: state,
          stars: stars,
          onBack: () => context.pop(),
        ),
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
  String? _freshNoteId;

  /// Notes folding away after a confirmed delete (#407).
  final _leavingNoteIds = <String>{};
  Timer? _freshTimer;
  final _freshKey = GlobalKey();

  String get _tripId => widget.tripId;
  JournalState get _state => widget.state;

  @override
  void dispose() {
    _freshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final notifier = ref.read(journalControllerProvider(_tripId).notifier);
    final currentDay = state.currentDayDate;
    final isEmptyDay =
        currentDay != null &&
        !state.isDayLocked(currentDay) &&
        state.isDayEmpty(currentDay);
    final showsCapsule =
        currentDay != null && !isEmptyDay && !state.isDayLocked(currentDay);

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: ListView(
            key: const Key('journal-content-list'),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              MediaQuery.paddingOf(context).bottom +
                  AppSpacing.xxl +
                  (showsCapsule
                      ? JournalBalloonBar.height +
                            JournalBalloonBar.balloonOverhang +
                            AppSpacing.lg
                      : 0),
            ),
            children: [
              JournalHeader(
                stars: widget.stars,
                onBack: widget.onBack,
                onStarsTap: () => context.pushNamed(
                  RouteNames.tripBonusTasks,
                  pathParameters: {'tripId': _tripId},
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
                if (isEmptyDay)
                  EmptyDayNotebook(
                    stamp: noteDayStamp(context, state, currentDay),
                    weekday: _capitalised(
                      L10nDates.weekday(
                        context.l10n.localeName,
                      ).format(currentDay),
                    ),
                    onWrite: () => _newNote(currentDay),
                    onAddPhoto: () => _addPhoto(currentDay),
                  )
                else ...[
                  _DayHeading(state: state, day: currentDay),
                  const SizedBox(height: AppSpacing.lg),
                  DayTimelineView(
                    key: ValueKey(currentDay),
                    day: currentDay,
                    photos: state.photosForCurrentDay,
                    notes: state.notesForCurrentDay,
                    allPhotos: state.photos,
                    filmMomentIds: ref.watch(filmMomentIdsProvider(_tripId)),
                    onPhotoTap: _openPhoto,
                    onNoteLongPress: _noteActions,
                    onNoteSwipeDelete: _confirmDelete,
                    leavingNoteIds: _leavingNoteIds,
                    freshNoteId: _freshNoteId,
                    freshNoteKey: _freshKey,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                JournalActionButtons(
                  onToDoTap: () => ToDoSheet.show(
                    context,
                    tripId: _tripId,
                    dayDate: currentDay,
                  ),
                  onViewWrapUpTap: () => context.pushNamed(
                    RouteNames.tripWrapUp,
                    pathParameters: {'tripId': _tripId},
                  ),
                  state: state,
                ),
              ],
            ],
          ),
        ),
        if (showsCapsule)
          Positioned(
            // The Journal's only bottom control — no app bar here (#410).
            // 20pt side insets, 30pt up (#414), never into the home
            // indicator.
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: math.max(
              30,
              MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
            ),
            child: JournalBalloonBar(
              onPhotoTap: () => _addPhoto(currentDay),
              onNoteTap: () => _newNote(currentDay),
            ),
          ),
      ],
    );
  }

  void _addPhoto(DateTime day) =>
      AddPhotoSheet.show(context, tripId: _tripId, dayDate: day);

  void _openPhoto(PhotoEntity photo) {
    final dayPhotos = _state.photosForCurrentDay;
    final index = dayPhotos.indexWhere((p) => p.id == photo.id);
    PhotoViewerPage.show(
      context,
      photos: index == -1 ? [photo] : dayPhotos,
      initialIndex: index == -1 ? 0 : index,
      onDelete: (photo) =>
          runDeletePhoto(ref: ref, tripId: _tripId, photo: photo),
      filmTripId: _tripId,
    );
  }

  Future<void> _newNote(DateTime selectedDay) async {
    final note = await composeNewNote(
      context,
      ref,
      tripId: _tripId,
      selectedDay: selectedDay,
    );
    if (note == null || !mounted) return;
    final notifier = ref.read(journalControllerProvider(_tripId).notifier);
    if (ref.read(journalControllerProvider(_tripId)).value?.currentDayDate !=
        note.dayDate) {
      notifier.selectDay(note.dayDate);
    }
    _markFresh(note.id);
  }

  void _markFresh(String noteId) {
    _freshTimer?.cancel();
    setState(() => _freshNoteId = noteId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _freshKey.currentContext;
      if (target == null || !target.mounted) return;
      // Its slot ends up ~250px from the top, then opens (spec §7).
      final viewport = Scrollable.maybeOf(target)?.position.viewportDimension;
      Scrollable.ensureVisible(
        target,
        alignment: viewport == null || viewport <= 0
            ? .5
            : (AppMotion.noteScrollTarget / viewport).clamp(0.0, 1.0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.noteScrollDuration,
        curve: AppMotion.noteCurve,
      );
    });
    _freshTimer = Timer(AppMotion.noteFreshFor, () {
      if (mounted) setState(() => _freshNoteId = null);
    });
  }

  Future<void> _noteActions(JournalNoteEntity note) async {
    final action = await NoteActionsSheet.show(
      context,
      note: note,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    if (!mounted) return;
    switch (action) {
      case NoteAction.edit:
        await _editNote(note);
      case NoteAction.delete:
        await _confirmDelete(note);
      case null:
        break;
    }
  }

  /// The note page on one note; its time and day stay. Clearing it and
  /// confirming deletes it (#276).
  Future<void> _editNote(JournalNoteEntity note) async {
    final l10n = context.l10n;
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final dictated = ValueNotifier(note.dictated);
    final photo = note.photoId == null
        ? null
        : _state.photos.where((p) => p.id == note.photoId).firstOrNull;
    final draft = await pushNotePage(
      context,
      state: _state,
      day: note.dayDate,
      stamp:
          '${noteDayStamp(context, _state, note.dayDate)} · '
          '${l10n.note_stampEdit(L10nDates.clock(l10n.localeName, use24h: use24h).format(note.takenAt.toLocal()))}',
      existingText: note.content,
      dictated: dictated,
      onPhoto: photo == null ? null : notePhotoAttachment(context, photo),
    );
    final wasDictated = dictated.value;
    dictated.dispose();
    if (draft == null || !mounted) return;
    final content = draft.trim();
    if (content == note.content.trim()) return;
    if (content.isEmpty) {
      // The note page already asked (#276).
      _delete(note);
      return;
    }
    showStarToast(context, l10n.timeline_noteUpdated);
    unawaited(
      // Failures surface via the updateNoteMutation listener.
      runUpdateNote(
        ref: ref,
        tripId: _tripId,
        noteId: note.id,
        content: content,
        dictated: wasDictated,
      ).then((_) {}, onError: (Object _) {}),
    );
  }

  Future<void> _confirmDelete(JournalNoteEntity note) async {
    final time = L10nDates.clock(
      context.l10n.localeName,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
    ).format(note.takenAt.toLocal());
    if (await DeleteNoteSheet.confirm(context, time: time) && mounted) {
      _delete(note);
    }
  }

  /// The card folds away first (#407, spec §7); then the note goes and the
  /// toast shows.
  void _delete(JournalNoteEntity note) {
    if (!_leavingNoteIds.add(note.id)) return;
    final fold = FoldAway.durationFor(context);
    setState(() {});
    unawaited(
      // Failures put the note back and surface via the listener.
      runDeleteNote(
        ref: ref,
        tripId: _tripId,
        noteId: note.id,
        foldFor: fold,
      ).then((_) {}, onError: (Object _) {}),
    );
    Timer(fold, () {
      if (!mounted) return;
      showStarToast(context, context.l10n.timeline_noteDeleted);
      // The note has just left the state; it no longer needs the flag.
      setState(() => _leavingNoteIds.remove(note.id));
    });
  }
}

String _capitalised(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Day 2 · Amsterdam" and "Thu 23 Oct · 6 photos · 3 notes" (spec §4).
class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.state, required this.day});

  final JournalState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photos = state.photosForDay(day).length;
    final notes = state.notesForDay(day).length;
    final subtitle = [
      L10nDates.weekdayDayMonth(l10n.localeName).format(day),
      if (photos > 0) l10n.timeline_photoCount(photos),
      if (notes > 0) l10n.timeline_noteCount(notes),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.isSingleDay
              ? state.trip.name
              : l10n.journal_dayTitle(
                  state.currentDayNumber ?? 1,
                  state.trip.name,
                ),
          style: AppTypography.screenTitle.copyWith(fontSize: 26),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          key: const Key('journal-day-subtitle'),
          style: AppTypography.timelineMeta.copyWith(fontSize: 12),
        ),
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
            context.l10n.journal_noDates,
            textAlign: TextAlign.center,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
