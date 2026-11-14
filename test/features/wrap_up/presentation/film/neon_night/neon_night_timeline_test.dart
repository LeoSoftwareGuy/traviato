import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';

void main() {
  final reference = NeonNightTimeline.reference();

  test("the reference film reproduces the spec's cue table (§5)", () {
    const expected = <(double, int, NeonNightSceneSpec)>[
      (0.000, 0, NnIgnitionSpec()),
      (3.810, 8, NnPlanSpec()),
      (9.524, 20, NnChapterCardSpec(chapter: 0, chapters: 3, isLong: true)),
      (17.143, 36, NnMomentSpec(chapter: 0, type: NnMomentType.split)),
      (20.952, 44, NnMomentSpec(chapter: 0, type: NnMomentType.burst)),
      (24.762, 52, NnChapterCardSpec(chapter: 1, chapters: 3, isLong: false)),
      (28.571, 60, NnMomentSpec(chapter: 1, type: NnMomentType.timeline)),
      (34.286, 72, NnChapterCardSpec(chapter: 2, chapters: 3, isLong: true)),
      (41.905, 88, NnMomentSpec(chapter: 2, type: NnMomentType.peak)),
      (45.714, 96, NnNoteSpec()),
      (51.429, 108, NnFinaleSpec()),
      (59.048, 124, NnEndingSpec()),
    ];
    expect(reference.scenes, hasLength(expected.length));
    for (var i = 0; i < expected.length; i++) {
      final (seconds, beat, spec) = expected[i];
      final scene = reference.scenes[i];
      expect(scene.spec, spec, reason: 'scene $i');
      expect(scene.start, closeTo(seconds, 5e-4), reason: '$spec');
      expect(reference.startBeats[i], beat, reason: '$spec');
    }
    expect(reference.totalBeats, 136);
    expect(reference.total, closeTo(64.762, 5e-4));
    expect(reference.finaleBeat, 108);
    expect(reference.finaleCue, closeTo(51.429, 5e-4));
    expect(reference.endingCue, closeTo(59.048, 5e-4));
  });

  test('scenes run end to end, every cue on a downbeat', () {
    for (final chapters in [1, 2, 3, 4, 5]) {
      for (final plan in [true, false]) {
        for (final note in [true, false]) {
          final t = NeonNightTimeline.standard(
            chapters,
            hasPlan: plan,
            hasNote: note,
          );
          for (var i = 0; i < t.scenes.length; i++) {
            expect(t.startBeats[i] % 4, 0, reason: '${t.scenes[i].spec}');
            expect(
              t.scenes[i].start,
              closeTo(t.beat.beatToSec(t.startBeats[i]), 1e-9),
            );
          }
          expect(t.totalBeats % 4, 0);
        }
      }
    }
  });

  test('length by chapter count (§9), summed from the scene rules', () {
    // 3–5 match the spec's table; 1 and 2 follow its zoom rule (the last
    // chapter gets the long card), not the table's 24 / 29 bars (#363
    // plan, open question 1).
    const bars = {1: 23, 2: 30, 3: 34, 4: 38, 5: 42};
    for (final MapEntry(key: chapters, value: expected) in bars.entries) {
      final t = NeonNightTimeline.standard(chapters);
      expect(t.totalBeats, expected * 4, reason: '$chapters chapters');
      expect(t.chapterCount, chapters);
    }
    expect(NeonNightTimeline.standard(4).total, closeTo(72.381, 5e-4));
    expect(NeonNightTimeline.standard(5).total, closeTo(80.0, 5e-4));
  });

  test('the zoom rule: the first and the last chapter get the long card', () {
    List<bool> longCards(int chapters) => [
      for (var i = 0; i < chapters; i++)
        (NeonNightTimeline.standard(chapters).chapterCard(i).spec
                as NnChapterCardSpec)
            .isLong,
    ];
    expect(longCards(1), [true]);
    expect(longCards(2), [true, true]);
    expect(longCards(3), [true, false, true]);
    expect(longCards(5), [true, false, false, false, true]);
  });

  test('the standard moments per chapter (§7)', () {
    final five = NeonNightTimeline.standard(5);
    final moments = [
      for (final s in five.scenes)
        if (s.spec case NnMomentSpec(:final chapter, :final type))
          (chapter, type),
    ];
    expect(moments, [
      (0, NnMomentType.split),
      (0, NnMomentType.burst),
      (1, NnMomentType.timeline),
      (2, NnMomentType.peak),
      (3, NnMomentType.burst),
      (4, NnMomentType.burst),
    ]);
  });

  test('no plan or no note: the scene is cut and later cues move up', () {
    final noPlan = NeonNightTimeline.standard(3, hasPlan: false);
    final noNote = NeonNightTimeline.standard(3, hasNote: false);
    final neither = NeonNightTimeline.standard(
      3,
      hasPlan: false,
      hasNote: false,
    );
    const cut = 5.714;
    expect(noPlan.film.first<NnPlanSpec>(), isNull);
    expect(noNote.film.first<NnNoteSpec>(), isNull);
    expect(
      noPlan.chapterCard(0).start,
      closeTo(reference.chapterCard(0).start - cut, 5e-4),
    );
    expect(noPlan.finaleCue, closeTo(reference.finaleCue - cut, 5e-4));
    expect(noNote.finaleCue, closeTo(reference.finaleCue - cut, 5e-4));
    expect(neither.total, closeTo(reference.total - 2 * cut, 1e-3));
    // The note sits right before the drop, so cutting it leaves the
    // chapters where they were.
    expect(noNote.chapterCard(2).start, reference.chapterCard(2).start);
  });

  test('another bpm rescales every cue', () {
    final slower = NeonNightTimeline.standard(3, beat: const NeonBeat(120));
    expect(slower.startBeats, reference.startBeats);
    expect(slower.finaleCue, closeTo(54, 1e-9));
    expect(slower.total, closeTo(68, 1e-9));
  });

  test('sceneAt: hard cuts on every cue, local beats from the cue', () {
    for (var i = 0; i < reference.scenes.length; i++) {
      final scene = reference.scenes[i];
      final atCue = reference.sceneAt(scene.start + 1e-9);
      expect(atCue.scene, scene);
      expect(atCue.lb, closeTo(0, 1e-6));
      if (i > 0) {
        expect(
          reference.sceneAt(scene.start - 1e-6).scene,
          reference.scenes[i - 1],
        );
      }
    }
    final ign = reference.sceneAt(3.5);
    expect(ign.scene.spec, const NnIgnitionSpec());
    expect(ign.lb, closeTo(3.5 / reference.beat.beat, 1e-9));
    expect(reference.sceneAt(-1).scene.spec, const NnIgnitionSpec());
    expect(reference.sceneAt(999).scene.spec, const NnEndingSpec());
    expect(reference.sceneAt(reference.total).scene.spec, const NnEndingSpec());
  });

  test('chrome anchors: chapter cards and the balloon moves (§4)', () {
    expect(reference.isChapterCard(10), isTrue);
    expect(reference.isChapterCard(25), isTrue);
    expect(reference.isChapterCard(18), isFalse);
    expect(reference.isChapterCard(1), isFalse);
    final (fromIgn, toCorner) = reference.ignitionToCorner;
    expect(fromIgn, closeTo(3.333, 5e-4));
    expect(toCorner, closeTo(3.810, 5e-4));
    final (fromCorner, toEnd) = reference.cornerToEnd;
    expect(fromCorner, closeTo(59.048 + 0.476, 1e-3));
    expect(toEnd, closeTo(59.048 + 1.190, 1e-3));
  });

  test('the same input gives the same timeline', () {
    expect(
      NeonNightTimeline.reference().film,
      NeonNightTimeline.reference().film,
    );
  });
}
