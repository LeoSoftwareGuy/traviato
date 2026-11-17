import 'package:equatable/equatable.dart';

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

  /// Copied from the old one-note-per-day model (`day_notes`), shown at its
  /// last edit.
  final bool legacy;

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
  ];
}
