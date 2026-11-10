import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_world.dart';

/// Within ±5 % per channel, the spec's tolerance for sampled colours.
Matcher _closeToColor(int argb) {
  final expected = Color(argb);
  return predicate<Color>(
    (c) =>
        (c.r - expected.r).abs() <= 0.05 &&
        (c.g - expected.g).abs() <= 0.05 &&
        (c.b - expected.b).abs() <= 0.05,
    'within 5% of $expected',
  );
}

double _luminance(Color c) => c.computeLuminance();

void main() {
  group('SkyStoryTimeline', () {
    test('3 chapters land on the reference film\'s boundaries and 54 s', () {
      final timeline = SkyStoryTimeline.forChapters(3);
      expect(timeline.total, 54.0);
      expect(
        [for (final s in timeline.scenes) s.start],
        [0, 5, 7, 16.5, 19.5, 29, 31.5, 43, 46],
      );
      expect(
        [for (final s in timeline.scenes) s.spec],
        const [
          SkyOpeningSpec(),
          SkyInterludeSpec(index: 0),
          SkyChapterSpec(index: 0, count: 3),
          SkyInterludeSpec(index: 1),
          SkyChapterSpec(index: 1, count: 3),
          SkyInterludeSpec(index: 2),
          SkyChapterSpec(index: 2, count: 3),
          SkyGatherSpec(),
          SkyOutroSpec(),
        ],
      );
    });

    test('1 to 5 chapters each give one page per chapter, back to back', () {
      for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
        final timeline = SkyStoryTimeline.forChapters(n);
        final chapters = [
          for (final s in timeline.scenes)
            if (s.spec is SkyChapterSpec) s.spec,
        ];
        expect(chapters, hasLength(n));
        for (var i = 1; i < timeline.scenes.length; i++) {
          expect(timeline.scenes[i].start, timeline.scenes[i - 1].end);
        }
      }
    });
  });

  group('SkyWorld camera', () {
    test('climbs continuously, never stops or jumps (no hard cuts)', () {
      for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
        final world = SkyWorld(SkyStoryTimeline.forChapters(n));
        const frame = 1 / 30;
        var previous = world.camera(0);
        for (var t = frame; t <= world.timeline.total; t += frame) {
          final now = world.camera(t);
          expect(now, greaterThanOrEqualTo(previous), reason: 'n=$n t=$t');
          // Never more than full speed in one frame.
          expect(now - previous, lessThanOrEqualTo(world.speed * frame + 1e-9));
          previous = now;
        }
      }
    });

    test('reaches the same height by the gather, whatever the length', () {
      for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
        final world = SkyWorld(SkyStoryTimeline.forChapters(n));
        expect(
          world.camera(world.gatherStart),
          closeTo(SkyWorld.climbToGather, 1e-6),
        );
      }
    });

    test('matches the reference: ~65 px/s, embers 0.5 → 6 s ≈ 263 px', () {
      final world = SkyWorld(SkyStoryTimeline.forChapters(3));
      expect(world.speed, closeTo(65.9, 0.5));
      expect(world.camera(6) - world.camera(0.5), closeTo(263, 15));
    });
  });

  group('SkyWorld sky', () {
    final world = SkyWorld(SkyStoryTimeline.forChapters(3));

    test('matches the sampled reference stills', () {
      // ref-00: sunset at the bottom of the frame, dusk at the top.
      expect(world.skyColor(1880, 0.5), _closeToColor(0xFFD97861));
      expect(world.skyColor(20, 0.5), _closeToColor(0xFF322556));
      // ref-30: night above, the last of the dusk below.
      expect(world.skyColor(20, 30), _closeToColor(0xFF13163B));
      expect(world.skyColor(1880, 30), _closeToColor(0xFF312456));
      // ref-48/54: flat outro night.
      expect(world.skyColor(20, 48), _closeToColor(0xFF0B0D26));
      expect(world.skyColor(1880, 53.8), _closeToColor(0xFF0D112E));
    });

    test('only ever gets darker', () {
      for (final row in [0.0, 960.0, 1920.0]) {
        var previous = _luminance(world.skyColor(row, 0));
        for (var t = 0.25; t <= world.timeline.total; t += 0.25) {
          final now = _luminance(world.skyColor(row, t));
          expect(now, lessThanOrEqualTo(previous + 1e-6), reason: 't=$t');
          previous = now;
        }
      }
    });

    test('stars only in the night; clouds gone in the outro', () {
      expect(SkyWorld.starVisibility(600), 0);
      expect(SkyWorld.starVisibility(3000), 1);
      expect(world.cloudVisibility(10), 1);
      expect(world.cloudVisibility(46), 0);
    });

    test('seeded layers are the same every time', () {
      expect(SkyWorld.embers, isNotEmpty);
      expect(SkyWorld.embers.first.x, SkyWorld.embers.first.x);
      final copy = SkyWorld(SkyStoryTimeline.forChapters(3));
      expect(copy.skyColor(500, 12), world.skyColor(500, 12));
    });
  });

  group('balloons', () {
    final timeline = SkyStoryTimeline.forChapters(3);

    test('the big balloon settles over the title, then leaves', () {
      final title = heroBalloonAt(3.5, timeline)!;
      expect(title.center.dx, 540);
      expect(title.center.dy, closeTo(700, 9));
      expect(title.width, 360);
      expect(heroBalloonAt(6.5, timeline), isNull);
    });

    test('it drifts across the middle between pages, not on them', () {
      expect(heroBalloonAt(12, timeline), isNull);
      final across = heroBalloonAt(18, timeline)!;
      expect(across.center.dx, closeTo(650, 1));
      expect(across.center.dy, closeTo(650, 9));
    });

    test('a page has its corner balloon, the gather does not', () {
      final corner = cornerBalloonAt(12, timeline)!;
      expect(corner.opacity, 1);
      expect(corner.center.dx, 930);
      expect(corner.center.dy, closeTo(145, 9));
      expect(cornerBalloonAt(45, timeline), isNull);
    });
  });

  testWidgets('the canvas plays through the whole film without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      SkyStoryCanvas(timeline: SkyStoryTimeline.forChapters(3)),
    );
    for (var t = 0; t < 54; t += 2) {
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull, reason: 't=$t');
    }
  });
}
