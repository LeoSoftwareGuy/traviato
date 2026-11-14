import '../timeline/film_timeline.dart';
import 'neon_beat.dart';
import 'neon_night_scene_spec.dart';
import 'neon_zoom_picks.dart';

/// What the timeline needs to know about one chapter: the moments that
/// follow its card, and how many photos it has (for its laser zooms).
class NnChapterShape {
  const NnChapterShape({required this.moments, required this.photos})
    : assert(photos >= 1, 'a chapter has photos');

  final List<NnMomentType> moments;
  final int photos;
}

/// Neon Night's scenes on the film clock (#363, NEON_NIGHT_SPEC.md §5, §9).
///
/// Laid out in beats and cut hard on every cue: Ignition, the optional
/// Plan, then per chapter its card and its moments, the optional Note, the
/// Finale (the drop) and the Ending. Every scene is a whole number of bars,
/// so every cue — and the drop — falls on a downbeat.
///
/// The first and the last chapter get the zoom card, the ones between the
/// short one (§9). Photo counts change densities, not length (§8), with
/// one exception (Leo, #363): a zoom card zooms each photo at most once,
/// so a first or last chapter with 1–2 photos gets a 12-beat zoom card
/// instead of 16.
class NeonNightTimeline {
  factory NeonNightTimeline({
    required List<NnChapterShape> chapters,
    bool hasPlan = true,
    bool hasNote = true,
    NeonBeat beat = const NeonBeat(),
  }) {
    assert(
      chapters.isNotEmpty && chapters.length <= maxChapters,
      'chapters: ${chapters.length}',
    );
    assert(
      chapters.every((c) => c.moments.isNotEmpty),
      'every chapter needs a moment',
    );
    final count = chapters.length;
    final specs = <NeonNightSceneSpec>[
      const NnIgnitionSpec(),
      if (hasPlan) const NnPlanSpec(),
      for (var i = 0; i < count; i++) ...[
        NnChapterCardSpec(
          chapter: i,
          chapters: count,
          zooms: i == 0 || i == count - 1
              ? NeonZoomPicks.countFor(chapters[i].photos)
              : 0,
        ),
        for (final type in chapters[i].moments)
          NnMomentSpec(chapter: i, type: type),
      ],
      if (hasNote) const NnNoteSpec(),
      const NnFinaleSpec(),
      const NnEndingSpec(),
    ];
    final startBeats = <int>[];
    var cursor = 0;
    for (final spec in specs) {
      startBeats.add(cursor);
      cursor += spec.beats;
    }
    return NeonNightTimeline._(
      beat: beat,
      startBeats: List.unmodifiable(startBeats),
      totalBeats: cursor,
      film: FilmTimeline.sequence([
        for (final spec in specs) (beat.beatToSec(spec.beats), spec),
      ]),
    );
  }

  /// [chapterCount] chapters with the spec's moments (§7): Ch 1 split +
  /// burst, Ch 2 timeline, Ch 3 peak, later chapters one two-bar moment.
  /// The reference shape and the fixtures' default; real memories pick
  /// their moments from their photos. Every chapter has [photos] photos.
  factory NeonNightTimeline.standard(
    int chapterCount, {
    int photos = 20,
    bool hasPlan = true,
    bool hasNote = true,
    NeonBeat beat = const NeonBeat(),
  }) => NeonNightTimeline(
    chapters: [
      for (var i = 0; i < chapterCount; i++)
        NnChapterShape(moments: standardMoments(i), photos: photos),
    ],
    hasPlan: hasPlan,
    hasNote: hasNote,
    beat: beat,
  );

  /// The reference film (§5): 3 chapters, a plan and a note, 136 beats.
  factory NeonNightTimeline.reference() => NeonNightTimeline.standard(3);

  const NeonNightTimeline._({
    required this.beat,
    required this.startBeats,
    required this.totalBeats,
    required this.film,
  });

  static const int maxChapters = 5;

  /// The spec's moments for chapter [index] (from 0), see [standard].
  static List<NnMomentType> standardMoments(int index) => switch (index) {
    0 => const [NnMomentType.split, NnMomentType.burst],
    1 => const [NnMomentType.timeline],
    2 => const [NnMomentType.peak],
    _ => const [NnMomentType.burst],
  };

  final NeonBeat beat;
  final FilmTimeline<NeonNightSceneSpec> film;

  /// Each scene's cue in beats, in play order (parallel to `film.scenes`).
  final List<int> startBeats;

  final int totalBeats;

  double get total => film.total;

  List<TimedScene<NeonNightSceneSpec>> get scenes => film.scenes;

  int get chapterCount =>
      scenes.where((s) => s.spec is NnChapterCardSpec).length;

  /// The drop: the Finale's cue.
  double get finaleCue => film.first<NnFinaleSpec>()!.start;

  /// The Finale's cue in beats.
  int get finaleBeat => startBeats[_indexOf<NnFinaleSpec>()];

  /// The end card's cue.
  double get endingCue => film.first<NnEndingSpec>()!.start;

  /// Chapter [chapter]'s card (from 0).
  TimedScene<NeonNightSceneSpec> chapterCard(int chapter) => scenes.firstWhere(
    (s) =>
        s.spec is NnChapterCardSpec &&
        (s.spec as NnChapterCardSpec).chapter == chapter,
  );

  /// When the balloon sign leaves its Ignition pose for the corner: the
  /// last beat of Ignition (§4.1).
  (double, double) get ignitionToCorner =>
      (beat.beatToSec(7), beat.beatToSec(8));

  /// When the balloon sign leaves the corner for its Ending pose: Ending
  /// lb 1 → 2.5 (§4.1).
  (double, double) get cornerToEnd =>
      (endingCue + beat.beatToSec(1), endingCue + beat.beatToSec(2.5));

  /// The scene playing at film time [t] (clamped to the film) and how many
  /// beats into it [t] is (its local beat `lb`).
  ({TimedScene<NeonNightSceneSpec> scene, double lb}) sceneAt(double t) {
    final clamped = t.clamp(0.0, total);
    var i = scenes.length - 1;
    while (i > 0 && clamped < scenes[i].start) {
      i--;
    }
    final scene = scenes[i];
    return (scene: scene, lb: beat.secToBeat(t - scene.start));
  }

  /// Whether a chapter card is on screen at [t]: the haze rises and the
  /// lasers take the chapter's colour (§4).
  bool isChapterCard(double t) => sceneAt(t).scene.spec is NnChapterCardSpec;

  int _indexOf<T extends NeonNightSceneSpec>() =>
      scenes.indexWhere((s) => s.spec is T);
}
