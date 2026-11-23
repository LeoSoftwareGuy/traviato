import 'package:equatable/equatable.dart';

import '../../../../core/utils/place_time.dart';

/// One timed note of a memory's day (#397). A day holds many, each saved by
/// its own Done, shown at [takenAt] in time order.
class JournalNoteEntity extends Equatable {
  const JournalNoteEntity({
    required this.id,
    required this.tripId,
    required this.dayDate,
    required this.takenAt,
    required this.editedAt,
    required this.content,
    this.dictated = false,
    this.photoId,
    this.legacy = false,
    this.utcOffsetMinutes,
  });

  final String id;
  final String tripId;

  /// The logical day the note belongs to, decided when it was saved
  /// ([logicalDayOf]) — not necessarily [takenAt]'s calendar date.
  final DateTime dayDate;

  /// When Done was first tapped. Edits never change it.
  final DateTime takenAt;
  final DateTime editedAt;
  final String content;

  /// Some of the text came from speech-to-text.
  final bool dictated;

  /// The photo the note was written on, if any.
  final String? photoId;

  /// Copied from the old one-note-per-day model (dropped, #406), shown at its
  /// last edit.
  final bool legacy;

  /// The device's UTC offset where it was written (#461), or resolved
  /// from the memory's zone ([onClockOf]); null = the phone's.
  final int? utcOffsetMinutes;

  /// [takenAt] on the clock of where it was written: for showing and for
  /// its day, never for ordering.
  DateTime get localTakenAt => placeTime(takenAt, utcOffsetMinutes);

  /// [editedAt] on the same clock.
  DateTime get localEditedAt => placeTime(editedAt, utcOffsetMinutes);

  /// This note with an offset from [zone] (the memory's) when it has none
  /// of its own.
  JournalNoteEntity onClockOf(String? zone) {
    if (utcOffsetMinutes != null) return this;
    final offset = zoneOffsetAt(zone, takenAt);
    return offset == null
        ? this
        : JournalNoteEntity(
            id: id,
            tripId: tripId,
            dayDate: dayDate,
            takenAt: takenAt,
            editedAt: editedAt,
            content: content,
            dictated: dictated,
            photoId: photoId,
            legacy: legacy,
            utcOffsetMinutes: offset,
          );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    dayDate,
    takenAt,
    editedAt,
    content,
    dictated,
    photoId,
    legacy,
    utcOffsetMinutes,
  ];
}
