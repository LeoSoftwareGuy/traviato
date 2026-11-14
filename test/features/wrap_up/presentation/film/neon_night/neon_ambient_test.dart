import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_ambient.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_random.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_tokens.dart';

void main() {
  final timeline = NeonNightTimeline.reference();
  final ambient = NeonAmbient(timeline);
  final reduced = NeonAmbient(timeline, reducedFlashing: true);
  final beat = timeline.beat;

  /// [lb] beats into the scene [scene] (its index in the reference).
  double at(int scene, double lb) =>
      timeline.scenes[scene].start + beat.beatToSec(lb);

  group('haze', () {
    test('three blobs circling their homes', () {
      expect(NeonAmbient.hazeCentre(0, 0), const Offset(300, 590));
      expect(
        NeonAmbient.hazeCentre(1, 0),
        Offset(820 + 90 * math.sin(2), 1080 + 70 * math.cos(1)),
      );
      final c = NeonAmbient.hazeCentre(2, 10);
      expect(c.dx, closeTo(520 + 90 * math.sin(2.1 + 4), 1e-9));
      expect(c.dy, closeTo(1560 + 70 * math.cos(1.7 + 2), 1e-9));
    });

    test('1.1 on chapter cards, 0.8 elsewhere, gone at the end', () {
      expect(ambient.hazeLevel(1), 0.8);
      expect(ambient.hazeLevel(10), 1.1);
      expect(ambient.hazeLevel(26), 1.1);
      expect(ambient.hazeLevel(30), 0.8);
      final total = timeline.total;
      expect(ambient.hazeLevel(total - beat.beat), closeTo(0.4, 1e-9));
      expect(ambient.hazeLevel(total), closeTo(0, 1e-9));
    });
  });

  group('lasers', () {
    test("swing about the spec's angles", () {
      final first = NeonAmbient.lasers.first;
      expect(ambient.laserAngle(first, 0), -18);
      // A quarter of its 4-bar period later: at the top of its swing.
      expect(ambient.laserAngle(first, beat.bar), closeTo(-8, 1e-9));
      final second = NeonAmbient.lasers[1];
      expect(
        ambient.laserAngle(second, 0),
        closeTo(200 + 8 * math.sin(1), 1e-9),
      );
      final end = ambient.laserEnd(first, 0);
      expect((end - first.pivot).distance, closeTo(2600, 1e-6));
    });

    test('opacity: amt × (0.45 + punch × 0.5 × beatEnv)', () {
      // On a beat in a groove scene: 0.45 + 0.6 × 0.5.
      expect(ambient.laserOpacity(at(3, 2) + 1e-9), closeTo(0.75, 1e-3));
      // In Note: amt 0.6.
      expect(
        ambient.laserOpacity(at(9, 2) + 1e-9),
        closeTo(0.6 * 0.75, 1e-3),
      );
      // On the drop: punch 1.
      expect(ambient.laserOpacity(at(10, 4) + 1e-9), closeTo(0.95, 1e-3));
      // Ending: falling to 0 over its first 3 beats.
      expect(
        ambient.laserOpacity(at(11, 1) + 1e-9),
        closeTo(2 / 3 * 0.75, 1e-3),
      );
      expect(ambient.laserOpacity(at(11, 3.5)), 0);
      // Reduced flashing: the beat punch × 0.4.
      expect(
        reduced.laserOpacity(at(10, 4) + 1e-9),
        closeTo(0.45 + 0.4 * 0.5, 1e-3),
      );
    });

    test('take the chapter accent during chapter cards', () {
      final beam = NeonAmbient.lasers.first;
      expect(ambient.laserColor(beam, 1), NeonColors.green);
      expect(ambient.laserColor(beam, 10), NeonColors.cyan);
      expect(ambient.laserColor(beam, 25), NeonColors.violet);
      expect(ambient.laserColor(beam, 35), NeonColors.green);
      expect(ambient.laserColor(beam, 42), NeonColors.green);
      expect(ambient.laserColor(NeonAmbient.lasers[2], 42), NeonColors.pink);
    });
  });

  test('chapter accents cycle cyan, violet, green, pink', () {
    expect(
      [for (var i = 0; i < 5; i++) NeonColors.chapterAccent(i)],
      [
        NeonColors.cyan,
        NeonColors.violet,
        NeonColors.green,
        NeonColors.pink,
        NeonColors.cyan,
      ],
    );
  });

  test('grain: re-placed every frame from rng(frame × 7 + 3)', () {
    final r = NeonRandom(10 * 7 + 3);
    final expected = Offset(r.next() * 240, r.next() * 240);
    expect(NeonAmbient.grainOffset(10 / 30), expected);
    expect(NeonAmbient.grainOffset(10.5 / 30), expected);
    expect(NeonAmbient.grainOffset(11 / 30), isNot(expected));
  });

  test('the film fades to black over its last 2 beats', () {
    final total = timeline.total;
    expect(ambient.outroBlack(total - beat.beatToSec(2)), 0);
    expect(ambient.outroBlack(total - beat.beat), closeTo(0.5, 1e-9));
    expect(ambient.outroBlack(total), closeTo(1, 1e-9));
    expect(ambient.outroBlack(10), 0);
  });
}
