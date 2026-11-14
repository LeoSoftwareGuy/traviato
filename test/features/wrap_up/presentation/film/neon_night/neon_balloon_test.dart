import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_balloon.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_tokens.dart';

void main() {
  final timeline = NeonNightTimeline.reference();
  final balloon = NeonBalloon(timeline);
  final reduced = NeonBalloon(timeline, reducedFlashing: true);
  final beat = timeline.beat;

  group('poses (§4.1)', () {
    test('Ignition, then the corner over its last beat', () {
      expect(balloon.poseAt(0), NeonBalloon.ignition);
      expect(balloon.poseAt(3.3), NeonBalloon.ignition);
      final mid = balloon.poseAt((3.333 + 3.810) / 2);
      expect(mid.width, lessThan(600));
      expect(mid.width, greaterThan(130));
      expect(balloon.poseAt(3.810), NeonBalloon.corner);
      // In the corner through the heart finale.
      expect(balloon.poseAt(30), NeonBalloon.corner);
      expect(balloon.poseAt(58), NeonBalloon.corner);
    });

    test('to the end pose over Ending lb 1 → 2.5', () {
      final ending = timeline.endingCue;
      expect(balloon.poseAt(ending + beat.beatToSec(1)), NeonBalloon.corner);
      expect(balloon.poseAt(ending + beat.beatToSec(2.5)), NeonBalloon.end);
      expect(balloon.poseAt(timeline.total), NeonBalloon.end);
    });

    test('a shorter film moves at its own cues', () {
      final noPlan = NeonNightTimeline.standard(1, hasPlan: false);
      final b = NeonBalloon(noPlan);
      expect(b.poseAt(noPlan.endingCue - 0.1), NeonBalloon.corner);
      expect(b.poseAt(noPlan.total), NeonBalloon.end);
    });
  });

  group('lighting (§5.1)', () {
    test('tubes light in order on Ignition beats 0, 1, 2, 2.5, 3, 3.5', () {
      expect(
        [for (final t in NeonTube.values) t.lightBeat],
        [
          0,
          1,
          2,
          2.5,
          3,
          3.5,
        ],
      );
      expect(
        [for (final t in NeonTube.values) t.color],
        [
          NeonColors.pink,
          NeonColors.pink,
          NeonColors.cyan,
          NeonColors.pink,
          NeonColors.green,
          NeonColors.green,
        ],
      );
      final bandsOn = beat.beatToSec(2);
      expect(balloon.tubeLevel(NeonTube.bands, bandsOn - 0.01), 0);
      expect(balloon.tubeLevel(NeonTube.bands, bandsOn + 0.05), 0.75);
      expect(balloon.tubeLevel(NeonTube.bands, bandsOn + 0.1), 0.12);
      expect(balloon.tubeLevel(NeonTube.bands, bandsOn + 0.4), 1);
      expect(balloon.tubeLevel(NeonTube.flame, 30), 1);
    });

    test('the flicker: one dip, then a ramp', () {
      expect(NeonBalloon.flicker(-0.01), 0);
      expect(NeonBalloon.flicker(0), 0.75);
      expect(NeonBalloon.flicker(0.07), 0.12);
      expect(NeonBalloon.flicker(0.245), closeTo(0.56, 1e-9));
      expect(NeonBalloon.flicker(0.32), 1);
    });

    test('reduced flashing: a 0.3 s fade, no dip', () {
      expect(reduced.tubeLevel(NeonTube.envelope, 0.15), closeTo(0.5, 1e-9));
      expect(reduced.tubeLevel(NeonTube.envelope, 0.3), 1);
      for (var dt = 0.0; dt < 0.3; dt += 0.01) {
        expect(
          NeonBalloon.fadeOn(dt + 0.01),
          greaterThanOrEqualTo(NeonBalloon.fadeOn(dt)),
        );
      }
    });
  });

  group('glow g', () {
    test('0.9 + 0.4 × beatEnv, 1.2 in Ending', () {
      expect(balloon.glowAt(beat.beatToSec(30) + 1e-9), closeTo(1.3, 1e-6));
      expect(balloon.glowAt(timeline.endingCue + 1), 1.2);
    });

    test('the Finale glow-up at lb 8: + 0.9, or + 0.3 reduced', () {
      final glowUp = timeline.finaleCue + beat.beatToSec(8) + 1e-9;
      expect(balloon.glowAt(glowUp), closeTo(1.3 + 0.9, 1e-6));
      expect(reduced.glowAt(glowUp), closeTo(1.3 + 0.3, 1e-6));
      // Before it, nothing extra.
      final before = timeline.finaleCue + beat.beatToSec(7) + 1e-9;
      expect(balloon.glowAt(before), closeTo(1.3, 1e-6));
    });
  });

  test('tube width: 4.5 in the corner, 11 at full size', () {
    expect(NeonBalloon.tubeWidth(130), 4.5);
    expect(NeonBalloon.tubeWidth(600), 11);
    expect(NeonBalloon.tubeWidth(330), closeTo(4.5 + 6.5 * 200 / 470, 1e-9));
  });

  test('every tube parses, inside the 200 × 300 viewBox', () {
    const box = Rect.fromLTWH(0, 0, 200, 300);
    for (final tube in NeonTube.values) {
      final bounds = tube.path.getBounds();
      expect(bounds.isEmpty, isFalse, reason: '$tube');
      expect(box.inflate(1).contains(bounds.topLeft), isTrue);
      expect(box.inflate(1).contains(bounds.bottomRight), isTrue);
    }
    expect(
      NeonTube.envelope.path.getBounds(),
      const Rect.fromLTRB(12, 12, 188, 226),
    );
  });
}
