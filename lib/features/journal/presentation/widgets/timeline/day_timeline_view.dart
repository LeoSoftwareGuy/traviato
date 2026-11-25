import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/l10n/l10n_dates.dart';
import '../../../../photo/domain/entities/photo_entity.dart';
import '../../../domain/day_timeline.dart';
import '../../../domain/entities/journal_note_entity.dart';
import 'fold_away.dart';
import 'fresh_note_in.dart';
import 'timeline_note_card.dart';
import 'timeline_photo_group.dart';
import 'timeline_rail.dart';

/// A day's "One timeline" (#401, docs/design/journal-notes/ §2–4): photos
/// and notes on one rail, oldest first, with the AFTER MIDNIGHT and LATER
/// dividers. [freshNoteId] is the note just saved: it slides in (a
/// crossfade under reduced motion), wears the JUST NOW chip, and gets
/// [freshNoteKey] so the page can scroll to it.
class DayTimelineView extends StatelessWidget {
  const DayTimelineView({
    required this.day,
    required this.photos,
    required this.notes,
    required this.allPhotos,
    required this.filmMomentIds,
    required this.onPhotoTap,
    required this.onNoteLongPress,
    this.onPhotoLongPress,
    this.onNoteSwipeDelete,
    this.leavingNoteIds = const {},
    this.leavingPhotoIds = const {},
    this.freshNoteId,
    this.freshNoteKey,
    super.key,
  });

  final DateTime day;

  /// The day's photos and notes.
  final List<PhotoEntity> photos;
  final List<JournalNoteEntity> notes;

  /// Every photo of the memory — a note's "On photo" may point at any.
  final List<PhotoEntity> allPhotos;
  final Set<String> filmMomentIds;
  final ValueChanged<PhotoEntity> onPhotoTap;
  final ValueChanged<JournalNoteEntity> onNoteLongPress;

  /// Long-press on a photo tile → Delete (#424).
  final ValueChanged<PhotoEntity>? onPhotoLongPress;

  /// iOS swipe → Delete on a note (#407).
  final ValueChanged<JournalNoteEntity>? onNoteSwipeDelete;

  /// Notes folding away after a confirmed delete (#407).
  final Set<String> leavingNoteIds;

  /// Photos folding away after a confirmed delete (#424).
  final Set<String> leavingPhotoIds;
  final String? freshNoteId;
  final GlobalKey? freshNoteKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final clock = L10nDates.clock(locale, use24h: use24h);
    final photosById = {for (final p in allPhotos) p.id: p};
    final notedPhotoIds = {
      for (final n in notes)
        if (n.photoId != null) n.photoId!,
    };
    final entries = buildDayTimeline(day: day, photos: photos, notes: notes);

    Widget row(TimelineEntry entry) => switch (entry) {
      TimelineAfterMidnight(:final date) => TimelineDivider(
        label: l10n.timeline_afterMidnight(
          L10nDates.weekdayDayMonth(locale).format(date),
        ),
      ),
      TimelineLater() => TimelineDivider(label: l10n.timeline_later),
      TimelinePhotoRow(:final photos, :final isLater) => TimelineRailRow(
        key: ValueKey('timeline-photo-row-${photos.first.id}'),
        label: isLater
            ? L10nDates.dayMonth(locale).format(photoTimeOf(photos.first))
            : clock.format(photoTimeOf(photos.first)),
        isNote: false,
        child: TimelinePhotoGroup(
          photos: photos,
          use24h: use24h,
          onPhotoTap: onPhotoTap,
          onPhotoLongPress: onPhotoLongPress,
          leavingPhotoIds: leavingPhotoIds,
          notedPhotoIds: notedPhotoIds,
          filmMomentIds: filmMomentIds,
        ),
      ),
      TimelineNoteRow(:final note, :final isLater) => FoldAway(
        key: ValueKey('timeline-note-fold-${note.id}'),
        isLeaving: leavingNoteIds.contains(note.id),
        child: FreshNoteIn(
          key: ValueKey('timeline-note-row-${note.id}'),
          isFresh: note.id == freshNoteId,
          child: TimelineRailRow(
            key: note.id == freshNoteId ? freshNoteKey : null,
            label: note.isBackfilled
                ? l10n.timeline_addedLater.toUpperCase()
                : isLater
                ? l10n.timeline_later.toUpperCase()
                : clock.format(note.localTakenAt),
            isNote: true,
            dictated: note.dictated,
            child: TimelineNoteCard(
              note: note,
              use24h: use24h,
              isFresh: note.id == freshNoteId,
              isLater: isLater,
              photo: note.photoId == null ? null : photosById[note.photoId],
              onPhotoTap: note.photoId == null
                  ? null
                  : () {
                      final photo = photosById[note.photoId];
                      if (photo != null) onPhotoTap(photo);
                    },
              onLongPress: () => onNoteLongPress(note),
              onSwipeDelete: onNoteSwipeDelete == null
                  ? null
                  : () => onNoteSwipeDelete!(note),
            ),
          ),
        ),
      ),
    };

    return Stack(
      key: const Key('journal-day-timeline'),
      children: [
        const TimelineRailLine(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final entry in entries) row(entry)],
        ),
      ],
    );
  }
}
