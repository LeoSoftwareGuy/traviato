import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';

void main() {
  const beat = NeonBeat();

  test("the reference grid: 126 bpm, the spec's beat and bar", () {
    expect(beat.beat, closeTo(0.476190, 1e-6));
    expect(beat.bar, closeTo(1.904762, 1e-6));
    expect(beat.beatToSec(108), closeTo(51.429, 5e-4));
    expect(beat.beatToSec(136), closeTo(64.762, 5e-4));
    expect(beat.secToBeat(beat.beatToSec(37.5)), closeTo(37.5, 1e-12));
  });

  test('another bpm rescales seconds, not beats', () {
    const slower = NeonBeat(120);
    expect(slower.beat, 0.5);
    expect(slower.beatToSec(108), 54);
  });

  test('beatEnv: 1 on every beat, ~0.03 just before the next', () {
    for (final b in [0, 1, 7, 108]) {
      expect(beat.beatEnv(beat.beatToSec(b) + 1e-9), closeTo(1, 1e-6));
    }
    final justBefore = beat.beatEnv(beat.beatToSec(5) - 1e-6);
    expect(justBefore, closeTo(math.exp(-beat.beat / 0.14), 1e-4));
    expect(justBefore, closeTo(0.033, 0.002));
    // Halfway through a beat.
    expect(
      beat.beatEnv(beat.beatToSec(3.5)),
      closeTo(math.exp(-0.5 * beat.beat / 0.14), 1e-9),
    );
  });

  test('flare: 0 before the hit, 1 on it, e^-1 one tau later', () {
    expect(NeonBeat.flare(0.99, 1, 0.3), 0);
    expect(NeonBeat.flare(1, 1, 0.3), 1);
    expect(NeonBeat.flare(1.3, 1, 0.3), closeTo(math.exp(-1), 1e-12));
  });

  test('frameAt quantises to 30 fps, exactly on frame times', () {
    for (var f = 0; f < 2000; f++) {
      expect(NeonBeat.frameAt(f / 30), f);
    }
    expect(NeonBeat.frameAt(1 / 30 - 1e-4), 0);
  });
}
