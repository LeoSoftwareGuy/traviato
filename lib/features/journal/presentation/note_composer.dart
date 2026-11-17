import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/context_l10n.dart';
import '../../../core/l10n/l10n_dates.dart';
import '../../../core/widgets/star_award_toast.dart';
import '../../photo/domain/entities/photo_entity.dart';
import '../../photo/presentation/widgets/storage_photo_image.dart';
import '../domain/day_timeline.dart';
import '../domain/entities/journal_note_entity.dart';
import 'controllers/journal_controller.dart';
import 'controllers/journal_state.dart';
import 'mutations/journal_mutations.dart';
import 'pages/note_page.dart';
import 'widgets/note_page/attached_polaroid.dart';
import 'widgets/note_page/note_title_page.dart';

/// "DAY 2 · THU 23 OCT", or just the date on a one-day memory — the start
/// of a note page's stamp.
String noteDayStamp(BuildContext context, JournalState state, DateTime day) {
  final l10n = context.l10n;
  final date = L10nDates.weekdayDayMonth(l10n.localeName).format(day);
  final index = state.dayDates.indexWhere(
    (d) => d.year == day.year && d.month == day.month && d.day == day.day,
  );
  return state.isSingleDay || index == -1
      ? date
      : l10n.journal_noteStamp(index + 1, date);
}

/// Opens the note page for a note's [day]; the polaroid is the day's first
/// photo, or [onPhoto]'s.
Future<String?> pushNotePage(
  BuildContext context, {
  required JournalState state,
  required DateTime day,
  required String stamp,
  required String existingText,
  required ValueNotifier<bool> dictated,
  NotePhotoAttachment? onPhoto,
}) async {
  final photos = state.photosForDay(day);
  final polaroid = onPhoto?.photo ?? (photos.isEmpty ? null : photos.first);
  final url = polaroid?.imageUrl;
  if (url != null) {
    // Best effort: usually cached already; never hold the page back.
    await precacheImage(
      StoragePhotoImage.providerFor(
        url: url,
        storagePath: polaroid!.storagePath,
        maxDecodeDimension: StoragePhotoImage.maxDecodeDimensionFor(
          notePolaroidPhotoSize,
          MediaQuery.devicePixelRatioOf(context),
        ),
      ),
      context,
    ).timeout(const Duration(milliseconds: 300), onTimeout: () {});
    if (!context.mounted) return null;
  }
  return Navigator.of(context).push(
    NotePageRoute(
      stamp: stamp,
      title: state.trip.name,
      existingText: existingText,
      photoCount: photos.length,
      photo: polaroid,
      dictated: dictated,
      onPhoto: onPhoto,
    ),
  );
}

/// [photo] as a note page shows it (#402): its time on the phone's clock,
/// and its caption, else its place.
NotePhotoAttachment notePhotoAttachment(
  BuildContext context,
  PhotoEntity photo,
) {
  final caption = photo.caption?.trim();
  return NotePhotoAttachment(
    photo: photo,
    time: L10nDates.clock(
      context.l10n.localeName,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
    ).format(photoTimeOf(photo)),
    line: caption != null && caption.isNotEmpty ? caption : photo.placeText,
  );
}

/// A new note (#397, #401, #402): an empty page; Done saves a separate
/// note timed at Done, on the logical day — after midnight still the
/// evening's — or on [photo] when given. Shows the ✦ toast (or "Note
/// saved" past the day's 3 starred notes) and returns the saved note;
/// null when nothing was written or the save failed (the
/// `createNoteMutation` listener reports that).
Future<JournalNoteEntity?> composeNewNote(
  BuildContext context,
  WidgetRef ref, {
  required String tripId,
  required DateTime selectedDay,
  PhotoEntity? photo,
}) async {
  final state = ref.read(journalControllerProvider(tripId)).value;
  if (state == null) return null;
  final l10n = context.l10n;
  final clock = L10nDates.clock(
    l10n.localeName,
    use24h: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final dayStamp = noteDayStamp(context, state, selectedDay);
  final nowLabel = clock.format(DateTime.now());
  final dictated = ValueNotifier(false);
  final draft = await pushNotePage(
    context,
    state: state,
    day: selectedDay,
    stamp:
        '$dayStamp · '
        '${photo == null ? l10n.note_stampNew(nowLabel) : l10n.note_stampPhoto(nowLabel)}',
    existingText: '',
    dictated: dictated,
    onPhoto: photo == null ? null : notePhotoAttachment(context, photo),
  );
  final wasDictated = dictated.value;
  dictated.dispose();
  final content = draft?.trim() ?? '';
  if (content.isEmpty || !context.mounted) return null;

  final latestState =
      ref.read(journalControllerProvider(tripId)).value ?? state;
  final now = DateTime.now();
  final latest = latestState.latestItemBefore(now);
  final day = _clampToTrip(
    latestState,
    dayForNewItem(
      selectedDay: selectedDay,
      now: now,
      previousAt: latest?.at,
      previousDay: latest?.day,
    ),
  );
  // The server stars a day's first 3 notes; this is the same count as far
  // as the app can see it.
  final earnsStar = latestState.notesForDay(day).length < maxStarredNotesPerDay;
  showStarToast(
    context,
    earnsStar ? l10n.toast_noteSaved : l10n.timeline_noteSavedNoStar,
  );
  try {
    return await runCreateNote(
      ref: ref,
      tripId: tripId,
      dayDate: day,
      takenAt: now,
      content: content,
      dictated: wasDictated,
      photoId: photo?.id,
    );
  } on Object {
    return null;
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
