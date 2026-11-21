import 'dart:math' as math;

import '../../../domain/film_text_rules.dart';
import 'neon_beat.dart';
import 'neon_chapter_card.dart';
import 'neon_moments.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_night_timeline.dart';
import 'neon_zoom_picks.dart';

/// How long Neon Night holds the user's words (#399 T1): every caption,
/// typed line and note stays readable for [FilmTextRules.readingTime].
/// Scenes that need more time grow by whole bars, so cuts stay on the
/// downbeat and the track still fits ([NeonTrack.partsFor]). A pure
/// function of the story and the clock: the film stays deterministic.
abstract final class NnReadingTime {
  /// [story]'s chapters as the timeline needs them, on [beat]'s clock.
  static List<NnChapterShape> chaptersFor(
    NeonNightStory story,
    NeonBeat beat,
  ) {
    return [
      for (final (i, chapter) in story.chapters.indexed)
        NnChapterShape(
          moments: [for (final moment in chapter.moments) moment.type],
          photos: chapter.cardPhotos.length,
          zoomHolds: zoomHolds(chapter, i + 1, beat),
          zooms: NnChapterTexts.zoomTilesFor(chapter, i + 1).length,
          cardMinBeats: cardBeats(chapter, beat),
          momentMinBeats: [
            for (final moment in chapter.moments) momentBeats(moment, beat),
          ],
        ),
    ];
  }

  /// The Note scene's fewest beats; 0 without one.
  static int noteBeats(NeonNightStory story, NeonBeat beat) =>
      switch (story.noteLines) {
        final lines? => NnNoteTexts.beatsFor(lines, beat),
        null => 0,
      };

  /// The extra beats each zoom of chapter [chapterNumber]'s card holds its
  /// photo: enough to read its caption in the big frame (lb c + 1 to
  /// c + 2½ + hold).
  static List<int> zoomHolds(
    NnChapter chapter,
    int chapterNumber,
    NeonBeat beat,
  ) {
    final picks = NnChapterTexts.zoomTilesFor(chapter, chapterNumber);
    return [
      for (final k in picks)
        switch (NnChapterTexts.zoomCaptionOf(
          chapter.cardPhotos[k],
          const NeonBeat(),
        )) {
          final caption? =>
            math
                .max(
                  0,
                  _ceil(
                    beat.secToBeat(FilmTextRules.readingTime(caption)) - 1.5,
                  ),
                )
                .clamp(0, NeonZoomPicks.maxHoldBeats),
          null => 0,
        },
    ];
  }

  /// The card's fewest beats for its typed line: typed from lb 4 one
  /// character a frame, then on screen for at least its reading time,
  /// before the 0.18 s fade. 0 without a line.
  static int cardBeats(NnChapter chapter, NeonBeat beat) {
    final typed = NnChapterTexts.typedTextFor(chapter.note);
    if (typed == null) return 0;
    final typing = ('> $typed'.runes.length) / NeonBeat.fps;
    final shown = math.max(typing + 0.8, FilmTextRules.readingTime(typed));
    return _bars(NnCardTiming.typeFrom + beat.secToBeat(shown + 0.18));
  }

  /// A moment's fewest beats for its captions; 0 when it shows none.
  static int momentBeats(NnMoment moment, NeonBeat beat) {
    final boxes = [
      for (final photo in moment.photos)
        moment is NnTimeline
            ? nnCaptionBox(
                photo,
                maxWidth: NnTimelineLayout.zoomWidth,
                withLine: true,
              )
            : nnCaptionBox(photo, withLine: true),
    ];
    final captions = boxes.nonNulls.toList();
    final int need;
    if (captions.isEmpty) {
      need = 0;
    } else if (moment is NnTimeline) {
      final holds = NnTimelineTexts.holdsFor(boxes, beat);
      need = _bars(2 + holds.fold(0, (a, b) => a + b) + beat.secToBeat(0.18));
    } else {
      final read = captions
          .map((c) => FilmTextRules.readingTime(c.text))
          .fold(0.0, (a, b) => a + b);
      need = _bars(1 + beat.secToBeat(read + 0.18));
    }
    for (final box in captions) {
      box.dispose();
    }
    return need;
  }

  static int _ceil(double beats) => (beats - 1e-9).ceil();

  /// [beats] rounded up to whole bars.
  static int _bars(double beats) => _ceil(beats / 4) * 4;
}
