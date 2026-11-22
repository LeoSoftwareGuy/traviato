import '../../../domain/wrap_up_limits.dart';
import 'neon_beat.dart';
import 'neon_night_canvas.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_track.dart';

/// Neon Night held to the longest film (#450): the film as the player
/// plays it ([NeonNightCanvas.timelineFor] on the music's clock) never
/// runs past [WrapUpLimits.longestFilmSeconds]. The edge function trims by
/// an estimate; this is the measure. Over the limit, one step at a time
/// in this order, the last chapter first:
/// 1. a moment's words 3 → 2;
/// 2. a chapter's two moments become one;
/// 3. the Plan scene goes;
/// 4. a long card line becomes its first short clause;
/// 5. a card's zooms 2 → 1 (never none).
/// Should the film still run over, more, so the limit holds:
/// 6. a card's zoom takes its quickest photo (no caption first);
/// 7. a moment's words 2 → 1;
/// 8. a moment's long line becomes its first short clause (#456);
/// 9. a moment's line goes (#456: on the phone ADE ran 77.4 s, every
///    other step spent).
/// Never a chapter, the Note scene, a chapter's line, its last zoom, nor
/// a moment's last caption (#456): a moment's words go captions first
/// while another caption stays, then its line is shortened, then it goes.
///
/// [lengthOf] lays the film out with the fonts the device has, so on the
/// phone it measures what plays; tests load the bundled fonts to match.
abstract final class NnFit {
  /// The longest a card line stays in step 4.
  static const int shortCardLine = 30;

  /// The most photos a merged moment shows.
  static const int mergedPhotos = 6;

  /// [story] trimmed until it plays within [maxSeconds] on [beat].
  static NeonNightStory toLongest(
    NeonNightStory story, {
    NeonBeat beat = NeonTrack.beat,
    double? maxSeconds,
  }) {
    final limit = maxSeconds ?? WrapUpLimits.longestFilmSeconds.toDouble();
    var s = story;
    for (var guard = 0; guard < 200; guard++) {
      if (lengthOf(s, beat) <= limit + 1e-6) return s;
      final next = _step(s);
      if (next == null) return s;
      s = next;
    }
    return s;
  }

  /// How long [story] plays on [beat], as the player lays it out.
  static double lengthOf(NeonNightStory story, NeonBeat beat) =>
      NeonNightCanvas.timelineFor(story, beat: beat).total;

  static NeonNightStory? _step(NeonNightStory s) {
    final last = s.chapters.length - 1;
    // 1. Words 3 → 2.
    if (_fewerWords(s, 2) case final next?) return next;
    // 2. Two moments → one.
    for (var i = last; i >= 0; i--) {
      final c = s.chapters[i];
      if (c.moments.length > 1) {
        final merged = _merged(c.moments);
        final kept = {for (final p in merged.photos) p.id};
        // What the merged moment leaves out joins the heart.
        final dropped = [
          for (final m in c.moments)
            for (final p in m.photos)
              if (!kept.contains(p.id)) p.id,
        ];
        final next = _withChapter(s, i, _chapter(c, moments: [merged]));
        return s.heartPhotoIds.isEmpty || dropped.isEmpty
            ? next
            : _story(next, heart: [...s.heartPhotoIds, ...dropped]);
      }
    }
    // 3. The Plan scene.
    if (s.plan.isNotEmpty) return _story(s, plan: const []);
    // 4. Long card lines.
    for (var i = last; i >= 0; i--) {
      final c = s.chapters[i];
      final note = c.note;
      if (note == null || note.runes.length <= shortCardLine) continue;
      final short = shortClause(note);
      if (short != null) return _withChapter(s, i, _chapter(c, note: short));
    }
    // 5. Zooms 2 → 1.
    for (var i = last; i >= 0; i--) {
      final c = s.chapters[i];
      if (NnChapterTexts.zoomTilesFor(c, i + 1).length > 1) {
        return _withChapter(s, i, _chapter(c, zooms: 1));
      }
    }
    // Past the five, 75 s still holds (#450):
    // 6. a card's zoom takes its quickest photo (no caption first);
    for (var i = last; i >= 0; i--) {
      final c = s.chapters[i];
      if (!c.quickZooms) {
        return _withChapter(s, i, _chapter(c, quickZooms: true));
      }
    }
    // 7. a moment's words 2 → 1.
    if (_fewerWords(s, 1) case final next?) return next;
    // 8. a moment's long line → its first short clause;
    for (var i = last; i >= 0; i--) {
      final c = s.chapters[i];
      for (final (j, m) in c.moments.indexed) {
        if (_shorterLine(m) case final shorter?) {
          return _withChapter(s, i, _withMoment(c, j, shorter));
        }
      }
    }
    // 9. a moment's line goes.
    for (var i = last; i >= 0; i--) {
      final c = s.chapters[i];
      for (final (j, m) in c.moments.indexed) {
        if (m.photos.any((p) => p.line != null)) {
          final quiet = _rebuilt(m, [
            for (final p in m.photos) p.line != null ? p.quiet : p,
          ]);
          return _withChapter(s, i, _withMoment(c, j, quiet));
        }
      }
    }
    return null;
  }

  /// [s] with one moment (the last chapter's first) down from more than
  /// [words] words by one, or null when none can be.
  static NeonNightStory? _fewerWords(NeonNightStory s, int words) {
    for (var i = s.chapters.length - 1; i >= 0; i--) {
      final c = s.chapters[i];
      for (final (j, m) in c.moments.indexed) {
        if (_worded(m).length <= words) continue;
        if (_quietOne(m) case final quieter?) {
          return _withChapter(s, i, _withMoment(c, j, quieter));
        }
      }
    }
    return null;
  }

  /// [m] with its first long line as its short clause; null if none.
  static NnMoment? _shorterLine(NnMoment m) {
    for (final (k, p) in m.photos.indexed) {
      final line = p.line;
      if (line == null || line.runes.length <= shortCardLine) continue;
      final short = shortClause(line);
      if (short == null || short == line) continue;
      return _rebuilt(m, [...m.photos]..[k] = p.quiet.withLine(short));
    }
    return null;
  }

  /// [line]'s first clause of 3 words or more that fits [shortCardLine]:
  /// the user's own words, never cut inside a clause. Null if none.
  static String? shortClause(String line) {
    for (final piece in line.split(RegExp(r'(?<=[,;:.!?])\s+'))) {
      final clause = piece.replaceAll(RegExp(r'[\s,;:—–-]+$'), '').trim();
      if (clause.split(RegExp(r'\s+')).length < 3) continue;
      if (clause.runes.length <= shortCardLine) return clause;
    }
    return null;
  }

  static List<NnPhoto> _worded(NnMoment m) => [
    for (final p in m.photos)
      if (p.line != null || p.caption != null) p,
  ];

  /// [m] with one word fewer (#456): a caption, the last first, while
  /// another caption stays; else its line — shortened to its first short
  /// clause while a caption stays, else gone. Null when only its last
  /// caption is left.
  static NnMoment? _quietOne(NnMoment m) {
    final captions = [
      for (final p in m.photos)
        if (p.line == null && p.caption != null) p,
    ];
    final lines = [
      for (final p in m.photos)
        if (p.line != null) p,
    ];
    if (captions.length > 1) {
      final drop = captions.last;
      return _rebuilt(m, [
        for (final p in m.photos) p == drop ? p.quiet : p,
      ]);
    }
    if (lines.isEmpty) return null;
    final photo = lines.last;
    final line = photo.line!;
    final short = line.runes.length > shortCardLine ? shortClause(line) : null;
    final kept = captions.isNotEmpty && short != null && short != line
        ? photo.quiet.withLine(short)
        : photo.quiet;
    return _rebuilt(m, [
      for (final p in m.photos) p == photo ? kept : p,
    ]);
  }

  /// One moment of [moments]' photos in time order: up to [mergedPhotos],
  /// photos with words first, the rest spread; at most 2 with words.
  static NnMoment _merged(List<NnMoment> moments) {
    final all = [
      for (final m in moments) ...m.photos,
    ]..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    var keep = all;
    if (all.length > mergedPhotos) {
      final worded = [
        for (final p in all)
          if (p.line != null || p.caption != null) p,
      ].take(mergedPhotos).toList();
      final rest = [
        for (final p in all)
          if (!worded.contains(p)) p,
      ];
      final room = mergedPhotos - worded.length;
      final spread = [
        for (var k = 0; k < room; k++)
          rest[room == 1
              ? rest.length ~/ 2
              : (k * (rest.length - 1) / (room - 1)).round()],
      ];
      keep = [
        for (final p in all)
          if (worded.contains(p) || spread.contains(p)) p,
      ];
    }
    var words = 0;
    keep = [
      for (final p in keep)
        if (p.line != null || p.caption != null)
          (++words > 2 ? p.quiet : p)
        else
          p,
    ];
    return keep.length >= 5 ? NnTimeline(keep) : NnSplit(keep);
  }

  static NnMoment _rebuilt(NnMoment m, List<NnPhoto> photos) => switch (m) {
    NnSplit(:final place) => NnSplit(photos, place: place),
    NnBurst() => NnBurst(photos),
    NnTimeline() => NnTimeline(photos),
    NnPeak() => NnPeak(photos),
  };

  static NnChapter _withMoment(NnChapter c, int j, NnMoment m) =>
      _chapter(c, moments: [...c.moments]..[j] = m);

  static NnChapter _chapter(
    NnChapter c, {
    List<NnMoment>? moments,
    String? note,
    int? zooms,
    bool? quickZooms,
  }) => NnChapter(
    title: c.title,
    from: c.from,
    to: c.to,
    photos: c.photos,
    moments: moments ?? c.moments,
    note: note ?? c.note,
    cardPhotos: c.cardPhotos,
    zooms: zooms ?? c.zooms,
    quickZooms: quickZooms ?? c.quickZooms,
  );

  static NeonNightStory _withChapter(NeonNightStory s, int i, NnChapter c) =>
      _story(s, chapters: [...s.chapters]..[i] = c);

  static NeonNightStory _story(
    NeonNightStory s, {
    List<NnChapter>? chapters,
    List<NnPlanRow>? plan,
    List<String>? heart,
  }) => NeonNightStory(
    title: s.title,
    date: s.date,
    chapters: chapters ?? s.chapters,
    plan: plan ?? s.plan,
    note: s.note,
    firstName: s.firstName,
    headline: s.headline,
    totals: s.totals,
    heartPhotoIds: heart ?? s.heartPhotoIds,
    targetSeconds: s.targetSeconds,
  );
}
