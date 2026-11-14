import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_ambient.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_ambient_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_balloon.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_grain.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';

void main() {
  final timeline = NeonNightTimeline.reference();

  test('the grain tile is the same bytes every time', () {
    final a = NeonGrain.pixels();
    expect(a, hasLength(240 * 240 * 4));
    expect(listEquals(a, NeonGrain.pixels()), isTrue);
    // Not flat: neighbouring pixels differ.
    expect(a[0] == a[4] && a[4] == a[8] && a[8] == a[12], isFalse);
  });

  group('export-ready (#345 rules)', () {
    Future<Uint8List> render(double t, {bool reduced = false}) async {
      final grain = await NeonGrain.load();
      final ambient = NeonAmbient(timeline, reducedFlashing: reduced);
      final balloon = NeonBalloon(timeline, reducedFlashing: reduced);
      final time = ValueNotifier(t);
      const size = Size(NeonAmbient.width, NeonAmbient.height);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final painter in <CustomPainter>[
        NeonBackPainter(ambient: ambient, time: time),
        NeonLaserPainter(ambient: ambient, time: time),
        NeonBalloonPainter(balloon: balloon, time: time),
        NeonFrontPainter(ambient: ambient, grain: grain, time: time),
      ]) {
        painter.paint(canvas, size);
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1080, 1920);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    testWidgets('the same instant renders the same pixels every time', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final t in const [0.05, 3.0, 12.0, 40.0, 55.5, 64.5]) {
          expect(
            listEquals(await render(t), await render(t)),
            isTrue,
            reason: 't = $t',
          );
        }
        expect(
          listEquals(
            await render(55.5, reduced: true),
            await render(55.5, reduced: true),
          ),
          isTrue,
        );
        expect(listEquals(await render(3), await render(40)), isFalse);
      });
    });
  });
}
