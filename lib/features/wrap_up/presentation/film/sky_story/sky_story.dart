import 'package:equatable/equatable.dart';

/// What one Sky Story film shows (#345): the opening title and one page per
/// chapter. Raw data only; the copy is composed in the film's language at
/// render time (`SkyStoryCopy`). Built from a wrap-up's `content.sky`
/// (`skyStoryFromWrapUp`) or a fixture.
class SkyStory extends Equatable {
  const SkyStory({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.pages,
    this.names,
    this.momentCount = 0,
    this.mosaicPhotoIds = const [],
  });

  /// The memory's name, the opening's big title.
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// Who was there, after the dates in the subtitle (`Mari & Jonas`).
  final String? names;

  /// One per chapter, in order (1 to 5).
  final List<SkyPage> pages;

  /// How each page lays out its photos, in order.
  List<SkyPageLayout> get layouts => [
    for (final (i, page) in pages.indexed)
      SkyPageLayout.forPage(i, pages.length, extras: page.extras.length),
  ];

  /// Every photo of the memory: the closing `{N} moments`.
  final int momentCount;

  /// Photos for the closing mosaic's tiles (up to [maxMosaicPhotos]),
  /// repeated across its ~260 tiles. Empty: placeholder tiles.
  final List<String> mosaicPhotoIds;

  static const maxMosaicPhotos = 60;

  /// Every photo the film shows, for preloading.
  Iterable<String> get photoIds sync* {
    for (final page in pages) {
      yield page.hero.id;
      for (final extra in page.extras) {
        yield extra.id;
      }
    }
  }

  @override
  List<Object?> get props => [
    title,
    startDate,
    endDate,
    names,
    pages,
    momentCount,
    mosaicPhotoIds,
  ];
}

/// One chapter's page: a day (or a run of days), its headline, a hero
/// photo with others around it, and the day's note.
class SkyPage extends Equatable {
  const SkyPage({
    required this.firstDay,
    required this.date,
    required this.photoCount,
    required this.hero,
    this.headline,
    this.lastDay,
    this.endDate,
    this.extras = const [],
    this.note,
    this.signature,
    this.skyLine,
  });

  /// Day numbers within the memory; [lastDay] is set when the page covers
  /// several days (`DAYS 4–7`).
  final int firstDay;
  final int? lastDay;

  /// The page's (first) day, and its last when it covers several.
  final DateTime date;
  final DateTime? endDate;

  /// Photos taken on the page's days.
  final int photoCount;

  /// The director's title for the page; null shows its place, else
  /// `Day 2` (`SkyPageCopy.headlineFor`).
  final String? headline;
  final SkyPhoto hero;

  /// Photos dealt under the hero or circling the balloon; up to
  /// [SkyPage.maxExtras] are shown.
  final List<SkyPhoto> extras;

  /// The day's note, and who signs it (a first name).
  final String? note;
  final String? signature;

  /// The director's line for a page without a note, written on the sky.
  final String? skyLine;

  static const maxExtras = 4;

  @override
  List<Object?> get props => [
    firstDay,
    lastDay,
    date,
    endDate,
    photoCount,
    headline,
    hero,
    extras,
    note,
    signature,
    skyLine,
  ];
}

class SkyPhoto extends Equatable {
  const SkyPhoto({required this.id, this.place, this.takenAt});

  final String id;

  /// Where it was taken, for the polaroid's caption (`Alfama`).
  final String? place;

  /// Local time it was taken; gives the caption its part of the day.
  final DateTime? takenAt;

  @override
  List<Object?> get props => [id, place, takenAt];
}

/// How a page lays out its photos (design-spec §5, the reference's three
/// days).
enum SkyPageLayout {
  /// Day 1: photos dealt into a stack, the hero dropped on top; the count
  /// in the eyebrow; the note fades in on its card.
  fan,

  /// Day 2: photos dealt into a grid, the hero taped over them; the count
  /// in a badge; the note is written on line by line.
  taped,

  /// Day 3: photos circle the balloon, then the hero spins in with a warm
  /// halo; the note is written on the night sky.
  flyOut;

  /// The first page is a fan, the last flies out, the ones between
  /// alternate taped / fan. One page: a fan.
  static SkyPageLayout forChapter(int index, int count) {
    if (index == 0) return fan;
    if (index == count - 1) return flyOut;
    return index.isOdd ? taped : fan;
  }

  /// [forChapter] for a page with [extras] photos around its hero: a taped
  /// page needs at least [minTapedExtras] to fill its grid, so with fewer
  /// it's a fan (#345, phase 6).
  static SkyPageLayout forPage(
    int index,
    int count, {
    required int extras,
  }) {
    final layout = forChapter(index, count);
    return layout == taped && extras < minTapedExtras ? fan : layout;
  }

  static const minTapedExtras = 2;
}
