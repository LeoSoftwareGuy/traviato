import '../timeline/film_timeline.dart';
import 'golden_vows_scene_spec.dart';

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
  }) : assert(heroes >= 0 && chapters >= 0, 'pages: $heroes, $chapters'),
       film = _build(hasPackingCard, heroes, chapters, hasCarousel);

  /// The reference wedding (spec §5).
  factory GoldenVowsTimeline.reference() => GoldenVowsTimeline();

  final bool hasPackingCard;
  final int heroes;
  final int chapters;
  final bool hasCarousel;
  final FilmTimeline<GoldenVowsSceneSpec> film;

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
    int heroes,
    int chapters,
    bool hasCarousel,
  ) {
    var number = 0;
    GvPageSpec page(GvPageKind kind, int index) =>
        GvPageSpec(kind: kind, number: ++number, index: index);
    return FilmTimeline.sequence([
      (invitationDur, const GvInvitationSpec()),
      if (hasPackingCard) (packingCardDur, const GvPackingCardSpec()),
      (albumRiseDur + turnDur, const GvAlbumOpenSpec()),
      for (var i = 0; i < heroes; i++)
        (heroDwell + turnDur, page(GvPageKind.hero, i)),
      for (var i = 0; i < chapters; i++)
        (chapterDwell + turnDur, page(GvPageKind.chapter, i)),
      if (hasCarousel) (carouselDwell + turnDur, page(GvPageKind.carousel, 0)),
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
