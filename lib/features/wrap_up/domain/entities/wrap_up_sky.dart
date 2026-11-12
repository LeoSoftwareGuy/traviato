import 'package:equatable/equatable.dart';

/// Sky Story's pages for a draft (#345), from `content.sky`: the director's
/// choices, or pages built by code when it couldn't plan. Ids only for
/// photos; the film resolves them against the memory's own photos.
class WrapUpSky extends Equatable {
  const WrapUpSky({
    required this.isFromDirector,
    required this.title,
    required this.pages,
    this.firstName,
    this.momentCount = 0,
    this.mosaicPhotoIds = const [],
  });

  /// The director chose the pages (else code-built).
  final bool isFromDirector;

  /// The memory's name.
  final String title;

  /// Signs the notes; null = no signature.
  final String? firstName;

  /// Every photo of the memory.
  final int momentCount;
  final List<String> mosaicPhotoIds;

  /// At least one, at most five, in day order.
  final List<WrapUpSkyPage> pages;

  @override
  List<Object?> get props => [
    isFromDirector,
    title,
    firstName,
    momentCount,
    mosaicPhotoIds,
    pages,
  ];
}

class WrapUpSkyPage extends Equatable {
  const WrapUpSkyPage({
    required this.firstDay,
    required this.date,
    required this.photoCount,
    required this.heroPhotoId,
    this.lastDay,
    this.endDate,
    this.headline,
    this.extraPhotoIds = const [],
    this.noteId,
    this.note,
    this.skyLine,
  });

  final int firstDay;

  /// Set when the page covers several days.
  final int? lastDay;
  final DateTime date;
  final DateTime? endDate;
  final int photoCount;

  /// null: the film shows the page's place, else `Day N`.
  final String? headline;
  final String heroPhotoId;
  final List<String> extraPhotoIds;
  final String? noteId;

  /// The note's text, the user's own words.
  final String? note;

  /// The director's line for a page without a note.
  final String? skyLine;

  @override
  List<Object?> get props => [
    firstDay,
    lastDay,
    date,
    endDate,
    photoCount,
    headline,
    heroPhotoId,
    extraPhotoIds,
    noteId,
    note,
    skyLine,
  ];
}
