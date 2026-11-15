import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_beat.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_chapter_card_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';

/// §6 flashing safety, checked frame by frame over whole films: the
/// full-frame flash overlay (chapter slams, the drop, the glow-up).
void main() {
  /// The full-frame flash opacity on every frame of [timeline].
  List<double> frames(NeonNightTimeline timeline, {required bool reduced}) {
    final flash = NeonFlashPainter(
      timeline: timeline,
      time: ValueNotifier(0),
      reducedFlashing: reduced,
    );
    final count = (timeline.total * NeonBeat.fps).floor();
    return [
      for (var f = 0; f < count; f++)
        flash.flashAt(f / NeonBeat.fps) + flash.dropAt(f / NeonBeat.fps),
    ];
  }

  /// The frames where a flash fires: the opacity jumps up.
  List<int> onsets(List<double> opacity) => [
    for (var f = 1; f < opacity.length; f++)
      if (opacity[f] - opacity[f - 1] > 0.05) f,
  ];

  for (final chapters in [1, 3, 5]) {
    for (final reduced in [false, true]) {
      final label = '$chapters chapters${reduced ? ', reduced' : ''}';
      final timeline = NeonNightTimeline.standard(chapters);
      final opacity = frames(timeline, reduced: reduced);
      final fired = onsets(opacity);

      test('$label: never more than 3 flashes in any 1 s window', () {
        for (final at in fired) {
          final inWindow = fired
              .where((f) => f >= at && f < at + NeonBeat.fps)
              .length;
          expect(inWindow, lessThanOrEqualTo(3), reason: 'from frame $at');
        }
      });

      test('$label: one slam per chapter, the drop and the glow-up', () {
        expect(fired, hasLength(chapters + 2));
      });

      test('$label: flashes stay soft', () {
        final peak = opacity.reduce((a, b) => a > b ? a : b);
        expect(peak, lessThanOrEqualTo(reduced ? 0.12 + 1e-9 : 0.5 + 1e-9));
      });
    }
  }
}
