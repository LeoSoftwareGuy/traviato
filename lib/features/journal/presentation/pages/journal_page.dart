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
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../home/domain/entities/profile_stats_entity.dart';
import '../../../home/presentation/controllers/profile_stats_controller.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/mutations/photo_mutations.dart';
import '../../../photo/presentation/pages/photo_viewer_page.dart';
import '../../../photo/presentation/widgets/add_photo_sheet.dart';
import '../../../photo/presentation/widgets/storage_photo_image.dart';
import '../../../wrap_up/presentation/providers/film_pick_providers.dart';
import '../../domain/day_timeline.dart';
import '../../domain/entities/journal_note_entity.dart';
import '../controllers/journal_controller.dart';
import '../controllers/journal_state.dart';
import '../mutations/journal_mutations.dart';
import '../widgets/day_range_hero.dart';
import '../widgets/day_tabs.dart';
import '../widgets/journal_action_buttons.dart';
import '../widgets/journal_header.dart';
import '../widgets/note_page/note_title_page.dart';
import '../widgets/timeline/capture_capsule.dart';
import '../widgets/timeline/day_timeline_view.dart';
import '../widgets/timeline/empty_day_notebook.dart';
import '../widgets/timeline/note_sheets.dart';
import '../widgets/to_do_sheet.dart';
import 'note_page.dart';

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
      extendBody: true,
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
  /// How long a just-saved note wears JUST NOW (spec §7).
  static const _freshFor = Duration(seconds: 3);

  String? _freshNoteId;
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
                  (showsCapsule ? capsuleHeight + AppSpacing.lg : 0),
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
                    stamp: _dayStamp(context, currentDay),
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
            left: 0,
            right: 0,
            // Above the bottom bar and its pulled-up ➕ (#401 deviation: the
            // spec's capsule replaces the bar; ours floats over it).
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
            child: Center(
              child: CaptureCapsule(
                onPhoto: () => _addPhoto(currentDay),
                onNote: () => _newNote(currentDay),
              ),
            ),
          ),
      ],
    );
  }

  String _dayStamp(BuildContext context, DateTime day) {
    final l10n = context.l10n;
    final date = L10nDates.weekdayDayMonth(l10n.localeName).format(day);
    return _state.isSingleDay
        ? date
        : l10n.journal_noteStamp(_state.currentDayNumber ?? 1, date);
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

  /// Best effort: the polaroid is usually cached already; never hold the
  /// page back for a slow download.
  Future<void> _precachePolaroid(PhotoEntity? photo) async {
    final url = photo?.imageUrl;
    if (url == null) return;
    await precacheImage(
      StoragePhotoImage.providerFor(
        url: url,
        storagePath: photo!.storagePath,
        maxDecodeDimension: StoragePhotoImage.maxDecodeDimensionFor(
          notePolaroidPhotoSize,
          MediaQuery.devicePixelRatioOf(context),
        ),
      ),
      context,
    ).timeout(const Duration(milliseconds: 300), onTimeout: () {});
  }

  Future<String?> _pushNotePage({
    required DateTime day,
    required String stamp,
    required String existingText,
    required ValueNotifier<bool> dictated,
  }) async {
    final photos = _state.photosForDay(day);
    final firstPhoto = photos.isEmpty ? null : photos.first;
    await _precachePolaroid(firstPhoto);
    if (!mounted) return null;
    return Navigator.of(context).push(
      NotePageRoute(
        stamp: stamp,
        title: _state.trip.name,
        existingText: existingText,
        photoCount: photos.length,
        photo: firstPhoto,
        dictated: dictated,
      ),
    );
  }

  /// Opens an empty page; every Done saves a separate note, timed at Done
  /// (#397), on the logical day — after midnight that's still the evening's.
  Future<void> _newNote(DateTime selectedDay) async {
    final l10n = context.l10n;
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final dictated = ValueNotifier(false);
    final draft = await _pushNotePage(
      day: selectedDay,
      stamp:
          '${_dayStamp(context, selectedDay)} · '
          '${l10n.note_stampNew(L10nDates.clock(l10n.localeName, use24h: use24h).format(DateTime.now()))}',
      existingText: '',
      dictated: dictated,
    );
    dictated.dispose();
    final content = draft?.trim() ?? '';
    if (content.isEmpty || !mounted) return;

    final state = ref.read(journalControllerProvider(_tripId)).value ?? _state;
    final now = DateTime.now();
    final latest = state.latestItemBefore(now);
    final day = _clampToTrip(
      state,
      dayForNewItem(
        selectedDay: selectedDay,
        now: now,
        previousAt: latest?.at,
        previousDay: latest?.day,
      ),
    );
    // The server gives ✦1 to a day's first 3 notes; this is the same count
    // as far as the app can see it.
    final earnsStar = state.notesForDay(day).length < maxStarredNotesPerDay;
    showStarToast(
      context,
      earnsStar ? l10n.toast_noteSaved : l10n.timeline_noteSavedNoStar,
    );

    final JournalNoteEntity note;
    try {
      note = await runCreateNote(
        ref: ref,
        tripId: _tripId,
        dayDate: day,
        takenAt: now,
        content: content,
        dictated: dictated.value,
      );
    } on Object {
      // Surfaced by the createNoteMutation listener in JournalPage.
      return;
    }
    if (!mounted) return;
    final notifier = ref.read(journalControllerProvider(_tripId).notifier);
    if (state.currentDayDate != day) notifier.selectDay(day);
    _markFresh(note.id);
  }

  void _markFresh(String noteId) {
    _freshTimer?.cancel();
    setState(() => _freshNoteId = noteId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _freshKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: .5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 380),
        curve: AppMotion.progressCurve,
      );
    });
    _freshTimer = Timer(_freshFor, () {
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
    final draft = await _pushNotePage(
      day: note.dayDate,
      stamp:
          '${_dayStamp(context, note.dayDate)} · '
          '${l10n.note_stampEdit(L10nDates.clock(l10n.localeName, use24h: use24h).format(note.takenAt.toLocal()))}',
      existingText: note.content,
      dictated: dictated,
    );
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
        dictated: dictated.value,
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

  void _delete(JournalNoteEntity note) {
    showStarToast(context, context.l10n.timeline_noteDeleted);
    unawaited(
      // Failures put the note back and surface via the listener.
      runDeleteNote(
        ref: ref,
        tripId: _tripId,
        noteId: note.id,
      ).then((_) {}, onError: (Object _) {}),
    );
  }
}

/// The memory's days, so a new note never lands outside them.
DateTime _clampToTrip(JournalState state, DateTime day) {
  final dates = state.dayDates;
  if (dates.isEmpty) return day;
  if (day.isBefore(dates.first)) return dates.first;
  if (day.isAfter(dates.last)) return dates.last;
  return day;
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
