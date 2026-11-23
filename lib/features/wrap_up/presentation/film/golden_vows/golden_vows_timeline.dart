import 'dart:math' as math;

import '../../../domain/film_text_rules.dart';
import '../timeline/film_timeline.dart';
import 'golden_vows_scene_spec.dart';
import 'golden_vows_story.dart';

/// Golden Vows' scenes on the film clock (#346), from the spec's rules
/// (golden-vows-spec.md §5): the reference wedding — the packing card, 4
/// photo-with-note pages, 3 chapters and the carousel — gives its 70 s and
/// its page table exactly.
///
/// Each page lies open for its dwell, then turns in [turnDur] while the
/// page under it is already showing; so a page's scene is its dwell plus
/// its turn. The heart page never turns: the album closes over it.
class GoldenVowsTimeline {
  GoldenVowsTimeline({
    this.hasPackingCard = true,
    this.heroes = 4,
    this.chapters = 3,
    this.hasCarousel = true,
    List<double> heroDwells = const [],
    List<double> chapterDwells = const [],
    this.dwellScale = 1,
    List<GvPageRef>? pageOrder,
  }) : assert(heroes >= 0 && chapters >= 0, 'pages: $heroes, $chapters'),
       film = _build(
         hasPackingCard,
         hasCarousel,
         heroDwells,
         chapterDwells,
         dwellScale,
         pageOrder ??
             [
               for (var i = 0; i < heroes; i++)
                 (kind: GvPageKind.hero, index: i),
               for (var i = 0; i < chapters; i++)
                 (kind: GvPageKind.chapter, index: i),
             ],
       );

  /// A memory's film: no packed items, no packing card; no carousel
  /// photos, no carousel page.
  ///
  /// With a target length (`content.film_seconds`, #434) every page lies
  /// open longer or shorter, by the same [dwellScale], so the film lasts
  /// about that long — a photo page never shorter than its note needs.
  factory GoldenVowsTimeline.forStory(GoldenVowsStory story) {
    GoldenVowsTimeline at(double scale) => GoldenVowsTimeline(
      hasPackingCard: story.hasPackingCard,
      heroes: story.heroes.length,
      chapters: story.chapters.length,
      hasCarousel: story.hasCarousel,
      heroDwells: [
        for (final hero in story.heroes)
          scale == 1
              ? heroDwellFor(hero.note)
              : math.max(heroDwell * scale, heroDwellFor(hero.note, floor: 0)),
      ],
      chapterDwells: [
        for (final chapter in story.chapters)
          chapterDwellFor(
            chapter.title,
            chapterDwell * scale * story.chapterDwellScale,
            note: chapter.isLineANote ? chapter.line : null,
          ),
      ],
      dwellScale: scale,
      pageOrder: story.pageOrder,
    );
    final target = story.targetSeconds;
    if (target == null) return at(1);
    var lo = minDwellScale;
    var hi = maxDwellScale;
    for (var k = 0; k < 40; k++) {
      final mid = (lo + hi) / 2;
      if (at(mid).total < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return at((lo + hi) / 2);
  }

  /// The reference wedding (spec §5).
  factory GoldenVowsTimeline.reference() => GoldenVowsTimeline();

  /// How far the pages' dwell stretches or shrinks to fit (#434).
  static const minDwellScale = 0.7;
  static const maxDwellScale = 1.8;

  final bool hasPackingCard;
  final int heroes;
  final int chapters;
  final bool hasCarousel;

  /// Every page's dwell × this (#434); 1 = the spec's.
  final double dwellScale;
  final FilmTimeline<GoldenVowsSceneSpec> film;

  /// How long a photo-with-note page lies open (#399 T1): the spec's 3 s,
  /// or long enough to read its note — seen from the turn that uncovers it
  /// to its own turn.
  static double heroDwellFor(String? note, {double floor = heroDwell}) {
    final text = note?.trim();
    if (text == null || text.isEmpty) return floor;
    return math.max(floor, FilmTextRules.readingTime(text) - turnDur);
  }

  /// How long a chapter page lies open (#458): [dwell], never shorter than
  /// its title — or the user's line on it ([note], #460) — takes to read,
  /// seen from the turn that uncovers it to its own turn.
  static double chapterDwellFor(String title, double dwell, {String? note}) =>
      math.max(
        math.max(dwell, FilmTextRules.readingTime(title.trim()) - turnDur),
        note == null || note.trim().isEmpty
            ? 0
            : FilmTextRules.readingTime(note.trim()) - turnDur,
      );

  static const invitationDur = 5.4;
  static const packingCardDur = 6.5;

  /// The closed album rises (1.0 s), then its cover turns.
  static const albumRiseDur = 1.0;
  static const turnDur = 1.25;

  static const heroDwell = 3.0;
  static const chapterDwell = 3.4;
  static const carouselDwell = 6.0;

  /// From the heart page lying open until the cover swings back over it.
  static const heartToClose = 7.6;

  /// From the cover swinging back until the ending starts.
  static const closeDur = 1.0;
  static const endingDur = 9.05;

  /// The last stretch over which everything but the background fades.
  static const fadeOutDur = 1.4;

  static FilmTimeline<GoldenVowsSceneSpec> _build(
    bool hasPackingCard,
    bool hasCarousel,
    List<double> heroDwells,
    List<double> chapterDwells,
    double dwellScale,
    List<GvPageRef> pageOrder,
  ) {
    var number = 0;
    GvPageSpec page(GvPageKind kind, int index) =>
        GvPageSpec(kind: kind, number: ++number, index: index);
    return FilmTimeline.sequence([
      (invitationDur, const GvInvitationSpec()),
      if (hasPackingCard) (packingCardDur, const GvPackingCardSpec()),
      (albumRiseDur + turnDur, const GvAlbumOpenSpec()),
      // The main and chapter pages in their play order (#460).
      for (final (:kind, :index) in pageOrder)
        if (kind == GvPageKind.hero)
          (
            (index < heroDwells.length ? heroDwells[index] : heroDwell) +
                turnDur,
            page(GvPageKind.hero, index),
          )
        else
          (
            (index < chapterDwells.length
                    ? chapterDwells[index]
                    : chapterDwell * dwellScale) +
                turnDur,
            page(GvPageKind.chapter, index),
          ),
      if (hasCarousel)
        (carouselDwell * dwellScale + turnDur, page(GvPageKind.carousel, 0)),
      (heartToClose, page(GvPageKind.heart, 0)),
      (closeDur, const GvAlbumCloseSpec()),
      (endingDur, const GvEndingSpec()),
    ]);
  }

  double get total => film.total;

  /// When the heart page lies open: the spec's h0.
  double get heartStart => film.scenes
      .firstWhere(
        (s) =>
            s.spec is GvPageSpec &&
            (s.spec as GvPageSpec).kind == GvPageKind.heart,
      )
      .start;

  /// When the packing card comes in, or null without one.
  double? get packingCardStart => film.first<GvPackingCardSpec>()?.start;

  /// When the ending starts: the spec's e.
  double get endingStart => film.first<GvEndingSpec>()!.start;

  /// When the cover swings back.
  double get closeStart => film.first<GvAlbumCloseSpec>()!.start;

  /// Every page turn's start, the cover's first, in order.
  late final List<double> turnStarts = [
    for (final scene in film.scenes)
      switch (scene.spec) {
        GvAlbumOpenSpec() => scene.start + albumRiseDur,
        GvPageSpec(kind: GvPageKind.heart) => null,
        GvPageSpec() => scene.end - turnDur,
        _ => null,
      },
  ].nonNulls.toList();
}
