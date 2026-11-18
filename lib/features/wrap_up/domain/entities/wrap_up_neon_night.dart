import 'package:equatable/equatable.dart';

/// The Neon Night party film for a draft (#363), from `content.neon_night`:
/// the director's chapters, moments and words for a party, rave, club
/// night, festival, concert or night out, with the photos code sorted into
/// them. Ids only for photos; the film resolves them against the memory's
/// own.
class WrapUpNeonNight extends Equatable {
  const WrapUpNeonNight({
    required this.title,
    required this.chapters,
    this.startDate,
    this.place,
    this.plan = const [],
    this.note,
    this.headline,
    this.firstName,
    this.totals,
    this.heartPhotoIds = const [],
  });

  /// The memory's name.
  final String title;
  final DateTime? startDate;
  final String? place;

  /// The user's quests with a time, in order.
  final List<WrapUpNeonPlanRow> plan;

  /// 1–5, in time order.
  final List<WrapUpNeonChapter> chapters;
  final WrapUpNeonNote? note;
  final String? headline;
  final String? firstName;
  final WrapUpNeonTotals? totals;

  /// The Finale's heart (#378): the photos without a moment of their own,
  /// Always picks only to top it up. Empty in older content → every
  /// chapter photo.
  final List<String> heartPhotoIds;

  @override
  List<Object?> get props => [
    title,
    startDate,
    place,
    plan,
    chapters,
    note,
    headline,
    firstName,
    totals,
    heartPhotoIds,
  ];
}

class WrapUpNeonPlanRow extends Equatable {
  const WrapUpNeonPlanRow({
    required this.time,
    required this.title,
    this.done = false,
  });

  /// 'HH:MM', the quest's own time.
  final String time;
  final String title;
  final bool done;

  @override
  List<Object?> get props => [time, title, done];
}

class WrapUpNeonPhoto extends Equatable {
  const WrapUpNeonPhoto({
    required this.id,
    required this.takenAt,
    this.caption,
  });

  final String id;
  final DateTime takenAt;

  /// The user's own caption from Photo detail (#387), exact; null = none.
  final String? caption;

  @override
  List<Object?> get props => [id, takenAt, caption];
}

class WrapUpNeonChapter extends Equatable {
  const WrapUpNeonChapter({
    required this.title,
    required this.photos,
    required this.moments,
    this.note,
    this.cardPhotoIds = const [],
    this.excerpts = const [],
    this.days = const [],
    this.rejectedExcerpts = const [],
  });

  final String title;

  /// In time order.
  final List<WrapUpNeonPhoto> photos;

  /// The card's own photos (#390), ids of [photos]: its grid and zooms,
  /// never a moment's. Empty in older content: the card shows [photos].
  final List<String> cardPhotoIds;

  /// The user's own words for the card, or null for no typed line.
  final String? note;
  final List<WrapUpNeonMoment> moments;

  /// The chapter's lines (#398), in time order, each over its photo.
  /// Empty in older content.
  final List<WrapUpNeonExcerpt> excerpts;

  /// The chapter's logical days (#398), in order. Empty in older content.
  final List<DateTime> days;

  /// The best lines the director and code left out (plan inspector).
  final List<WrapUpNeonRejectedExcerpt> rejectedExcerpts;

  @override
  List<Object?> get props => [
    title,
    photos,
    note,
    moments,
    cardPhotoIds,
    excerpts,
    days,
    rejectedExcerpts,
  ];
}

/// An exact excerpt of one of the user's notes (#398).
class WrapUpNeonExcerpt extends Equatable {
  const WrapUpNeonExcerpt({
    required this.text,
    required this.noteId,
    this.photoId,
    this.fromDirector = false,
    this.score = 0,
  });

  final String text;
  final String noteId;

  /// The chapter photo it plays over; null = the app picks.
  final String? photoId;

  /// Chosen by the director, else picked by code.
  final bool fromDirector;

  /// How specific it is (numbers, names, food, firsts… minus summaries).
  final int score;

  @override
  List<Object?> get props => [text, noteId, photoId, fromDirector, score];
}

class WrapUpNeonRejectedExcerpt extends Equatable {
  const WrapUpNeonRejectedExcerpt({required this.text, required this.score});

  final String text;
  final int score;

  @override
  List<Object?> get props => [text, score];
}

/// `split`, `burst`, `timeline` or `peak`, over some of a chapter's photos.
class WrapUpNeonMoment extends Equatable {
  const WrapUpNeonMoment({
    required this.type,
    required this.photoIds,
    this.place,
  });

  final String type;
  final List<String> photoIds;

  /// A split's label.
  final String? place;

  @override
  List<Object?> get props => [type, photoIds, place];
}

class WrapUpNeonNote extends Equatable {
  const WrapUpNeonNote({
    required this.text,
    required this.number,
    this.writtenAt,
    this.photoId,
  });

  /// An exact excerpt of the user's note.
  final String text;

  /// Its place among the memory's notes, from 1.
  final int number;
  final DateTime? writtenAt;
  final String? photoId;

  @override
  List<Object?> get props => [text, number, writtenAt, photoId];
}

class WrapUpNeonTotals extends Equatable {
  const WrapUpNeonTotals({
    required this.photos,
    required this.notes,
    required this.ticks,
    required this.moments,
  });

  final int photos;
  final int notes;
  final int ticks;
  final int moments;

  @override
  List<Object?> get props => [photos, notes, ticks, moments];
}
