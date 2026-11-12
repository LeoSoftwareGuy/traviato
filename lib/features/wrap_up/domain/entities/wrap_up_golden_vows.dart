import 'package:equatable/equatable.dart';

/// The Golden Vows wedding album for a draft (#346), from
/// `content.golden_vows`: the director's words for a wedding, engagement,
/// anniversary or date night, and the photos code picked around them. Ids
/// only for photos; the film resolves them against the memory's own.
class WrapUpGoldenVows extends Equatable {
  const WrapUpGoldenVows({
    required this.names,
    required this.heroes,
    required this.chapters,
    this.occasion,
    this.occasionLine,
    this.startDate,
    this.dayCount = 1,
    this.place,
    this.packing,
    this.carousel,
    this.heartPhotoIds = const [],
    this.momentCount = 0,
    this.endLine,
  });

  /// `wedding`, `engagement`, `anniversary` or `date_night`.
  final String? occasion;
  final String? occasionLine;

  /// The memory's name.
  final String names;
  final DateTime? startDate;
  final int dayCount;
  final String? place;
  final WrapUpGoldenVowsPacking? packing;
  final List<WrapUpGoldenVowsHero> heroes;
  final List<WrapUpGoldenVowsChapter> chapters;
  final WrapUpGoldenVowsChapter? carousel;
  final List<String> heartPhotoIds;

  /// Every photo the film could show.
  final int momentCount;
  final String? endLine;

  @override
  List<Object?> get props => [
    occasion,
    occasionLine,
    names,
    startDate,
    dayCount,
    place,
    packing,
    heroes,
    chapters,
    carousel,
    heartPhotoIds,
    momentCount,
    endLine,
  ];
}

/// The packing card: checked checklist items, or the planned quests.
class WrapUpGoldenVowsPacking extends Equatable {
  const WrapUpGoldenVowsPacking({
    required this.items,
    this.isFromQuests = false,
    this.checked,
    this.total,
  });

  /// At least one, in the user's own words.
  final List<WrapUpGoldenVowsPackedItem> items;
  final bool isFromQuests;

  /// "X OF Y" (checklist only).
  final int? checked;
  final int? total;

  @override
  List<Object?> get props => [items, isFromQuests, checked, total];
}

class WrapUpGoldenVowsPackedItem extends Equatable {
  const WrapUpGoldenVowsPackedItem(this.text, {this.suggestionCode});

  final String text;

  /// A seeded checklist item's code: shown in the film's language.
  final String? suggestionCode;

  @override
  List<Object?> get props => [text, suggestionCode];
}

class WrapUpGoldenVowsHero extends Equatable {
  const WrapUpGoldenVowsHero({
    required this.photoId,
    this.label,
    this.takenAt,
    this.note,
  });

  final String photoId;

  /// "The vows"; the film adds the photo's time.
  final String? label;
  final DateTime? takenAt;

  /// The user's own words, or null for no note card.
  final String? note;

  @override
  List<Object?> get props => [photoId, label, takenAt, note];
}

class WrapUpGoldenVowsChapter extends Equatable {
  const WrapUpGoldenVowsChapter({
    required this.title,
    required this.photoIds,
    this.line,
    this.layout,
  });

  final String title;
  final String? line;
  final List<String> photoIds;

  /// `A`, `B` or `C`; null (the carousel, or unknown) = the film's own.
  final String? layout;

  @override
  List<Object?> get props => [title, line, photoIds, layout];
}
