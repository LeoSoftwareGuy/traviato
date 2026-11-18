import 'dart:math' as math;

import '../timeline/film_scene_spec.dart';
import 'neon_chapter_card.dart';

/// What one scene of the Neon Night film shows (#363,
/// NEON_NIGHT_SPEC.md §5). Every scene is a whole number of bars; its
/// length in beats lives on the spec so the timeline can lay the film out
/// on the beat grid.
sealed class NeonNightSceneSpec extends FilmSceneSpec {
  const NeonNightSceneSpec();

  /// How long the scene lasts, in beats.
  int get beats;
}

/// The neon balloon sign lights up, tube by tube, over the title (§5.1).
final class NnIgnitionSpec extends NeonNightSceneSpec {
  const NnIgnitionSpec();

  @override
  int get beats => 8;

  @override
  List<Object?> get props => const [];
}

/// "Tonight's plan": the night's quests ticked off on the beat (§5.2).
final class NnPlanSpec extends NeonNightSceneSpec {
  const NnPlanSpec();

  @override
  int get beats => 12;

  @override
  List<Object?> get props => const [];
}

/// A chapter's card: header, ghost numeral, title, contact sheet, typed
/// line and progress bar (§5.3).
///
/// The first and the last chapter get the zoom card (§9). Every zoom card
/// plays laser zooms, however few photos the chapter has (this overrides
/// §8's "fewer than 4 tiles → no zooms", Leo, #363), one per photo and
/// never the same one twice (`NeonZoomPicks`). Its length follows the
/// zooms: 3 zooms → 16 beats; 1–2 zooms → 12 beats (each zoom takes 3
/// beats from lb 6, kept to whole bars); no zooms → the 8-beat card.
final class NnChapterCardSpec extends NeonNightSceneSpec {
  const NnChapterCardSpec({
    required this.chapter,
    required this.chapters,
    required this.zooms,
    this.zoomHolds = const [],
    this.minBeats = 0,
  }) : assert(zooms >= 0 && zooms <= 3, 'zooms: $zooms'),
       assert(minBeats % 4 == 0, 'whole bars: $minBeats');

  /// Which chapter, from 0.
  final int chapter;

  /// How many chapters the film has.
  final int chapters;

  /// How many laser zooms the card plays, 0–3.
  final int zooms;

  /// The extra beats each zoom holds on its captioned photo (#399 T1).
  final List<int> zoomHolds;

  /// The fewest beats the card plays, so its typed line can be read
  /// (#399 T1); whole bars. 0 = the spec's length.
  final int minBeats;

  bool get hasZooms => zooms > 0;

  @override
  int get beats => math.max(
    NnCardTiming.beatsFor(zooms, [
      for (var i = 0; i < zooms; i++) i < zoomHolds.length ? zoomHolds[i] : 0,
    ]),
    minBeats,
  );

  @override
  List<Object?> get props => [chapter, chapters, zooms, zoomHolds, minBeats];
}

/// The block that shows a chapter's photos after its card (§5.4–5.6, §7).
enum NnMomentType {
  /// 2–3 tall strips side by side.
  split(8),

  /// 2–4 tilted frames popping in.
  burst(8),

  /// 2–8 photos in a scrolling masonry, highlighted in turn.
  timeline(12),

  /// 3–5 strips fanned out over a laser fan.
  peak(8);

  const NnMomentType(this.beats);

  final int beats;
}

/// One of a chapter's moments (§5.4–5.6).
final class NnMomentSpec extends NeonNightSceneSpec {
  const NnMomentSpec({
    required this.chapter,
    required this.type,
    this.minBeats = 0,
  }) : assert(minBeats % 4 == 0, 'whole bars: $minBeats');

  /// Which chapter, from 0.
  final int chapter;

  final NnMomentType type;

  /// The fewest beats the moment plays, so its captions can be read
  /// (#399 T1); whole bars. 0 = the type's length.
  final int minBeats;

  @override
  int get beats => math.max(type.beats, minBeats);

  @override
  List<Object?> get props => [chapter, type, minBeats];
}

/// The user's own words in neon tubes, over a blurred photo (§5.7).
final class NnNoteSpec extends NeonNightSceneSpec {
  const NnNoteSpec({this.minBeats = 0})
    : assert(minBeats % 4 == 0, 'whole bars: $minBeats');

  /// The fewest beats the scene plays, so the note can be read (#399 T1);
  /// whole bars. 0 = the spec's 12.
  final int minBeats;

  @override
  int get beats => math.max(12, minBeats);

  @override
  List<Object?> get props => [minBeats];
}

/// The drop: every photo pops into a heart, which beats (§5.8).
final class NnFinaleSpec extends NeonNightSceneSpec {
  const NnFinaleSpec();

  @override
  int get beats => 16;

  @override
  List<Object?> get props => const [];
}

/// The end card: moments, numbers, title and "Storyni" (§5.9).
final class NnEndingSpec extends NeonNightSceneSpec {
  const NnEndingSpec();

  @override
  int get beats => 12;

  @override
  List<Object?> get props => const [];
}
