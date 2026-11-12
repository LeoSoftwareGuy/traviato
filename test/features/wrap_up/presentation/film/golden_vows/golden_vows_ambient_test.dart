import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_ambient.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_ambient_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';

void main() {
  final ambient = GoldenVowsAmbient(GoldenVowsTimeline.reference());

  group('light leaks', () {
    test('drift out and back on 17.5 s legs, 0.32 ↔ 0.45', () {
      expect(GoldenVowsAmbient.leakDrift(0), 0);
      expect(GoldenVowsAmbient.leakDrift(8.75), closeTo(0.5, 1e-9));
      expect(GoldenVowsAmbient.leakDrift(17.5), closeTo(1, 1e-9));
      expect(GoldenVowsAmbient.leakDrift(35), closeTo(0, 1e-9));
      expect(GoldenVowsAmbient.leakDrift(52.5), closeTo(1, 1e-9));
      // Longer films keep going.
      expect(GoldenVowsAmbient.leakDrift(87.5), closeTo(1, 1e-9));
      expect(GoldenVowsAmbient.leakOpacity(0), 0.32);
      expect(GoldenVowsAmbient.leakOpacity(17.5), closeTo(0.45, 1e-9));
      final a = GoldenVowsAmbient.leaks.first;
      expect(a.centreAt(17.5), const Offset(380, 440));
    });

    test('fall off like a disc blurred by 170 px', () {
      final a = GoldenVowsAmbient.leaks.first;
      expect(a.falloff(0), greaterThan(0.99));
      expect(a.falloff(a.radius), closeTo(0.5, 1e-6));
      expect(a.falloff(a.reach), lessThan(0.002));
    });
  });

  group('petals', () {
    test('drawn from seed 11 in the spec order', () {
      expect(GoldenVowsAmbient.petals, hasLength(16));
      final p = GoldenVowsAmbient.petals.first;
      expect(p.x, closeTo(298.412991380319, 1e-9));
      expect(p.width, closeTo(27.28728308994323, 1e-9));
      expect(p.height, closeTo(15.88397259451449, 1e-9));
      expect(p.fallDur, closeTo(12.459273289889097, 1e-9));
      expect(p.spin, closeTo(234.05331410467625, 1e-9));
      expect(p.sway, closeTo(90.24027318926528, 1e-9));
      expect((p.color.a * 255).round(), 177);
    });

    test('fall from their phase, loop, and sway', () {
      final p = GoldenVowsAmbient.petals.first;
      final start = p.positionAt(0);
      expect(start.dy, closeTo(-60 + p.phase * 2060, 1e-9));
      expect(start.dx, closeTo(p.x - p.sway, 1e-9));
      // One fall later it's back where it started.
      expect(p.positionAt(p.fallDur).dy, closeTo(start.dy, 1e-6));
      expect(p.positionAt(1.4).dx, closeTo(p.x, 1e-9));
    });
  });

  group('gold frame', () {
    test('draws on from 0.2 / 0.45 over 2.6 s', () {
      expect(GoldenVowsAmbient.outerDrawn(0.2), 0);
      expect(GoldenVowsAmbient.outerDrawn(1.5), closeTo(0.5, 1e-9));
      expect(GoldenVowsAmbient.outerDrawn(2.8), 1);
      expect(GoldenVowsAmbient.innerDrawn(1.75), closeTo(0.5, 1e-9));
    });

    test('shows for the invitation and the ending only', () {
      expect(ambient.frameOpacity(3), 1);
      expect(ambient.frameOpacity(6.0), closeTo(0, 1e-9));
      expect(ambient.frameOpacity(30), closeTo(0, 1e-9));
      expect(ambient.frameOpacity(60.95 + 1.2), closeTo(0, 1e-9));
      expect(ambient.frameOpacity(60.95 + 2.8), closeTo(1, 1e-9));
      expect(ambient.frameOpacity(68.6), closeTo(1, 1e-9));
      expect(ambient.frameOpacity(70), closeTo(0, 1e-9));
    });
  });

  test('the flare sweeps 0.3 s into each turn, for 1.6 s', () {
    // The cover turns at 12.9.
    expect(ambient.flareAt(13.1), isNull);
    final mid = ambient.flareAt(14.0)!;
    expect(mid.left, closeTo(300, 1e-9));
    expect(mid.opacity, closeTo(0.3, 1e-9));
    expect(ambient.flareAt(14.9), isNull);
    // Page 1 turns at 17.15.
    expect(ambient.flareAt(17.15 + 0.3 + 0.8)!.left, closeTo(300, 1e-9));
    // Between turns and over the heart, none.
    expect(ambient.flareAt(16), isNull);
    expect(ambient.flareAt(55), isNull);
  });

  group('export-ready (#345 rules)', () {
    Future<Uint8List> render(double t) async {
      final time = ValueNotifier(t);
      const size = Size(GoldenVowsAmbient.width, GoldenVowsAmbient.height);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      GoldenVowsBackPainter(ambient: ambient, time: time).paint(canvas, size);
      GoldenVowsFrontPainter(ambient: ambient, time: time).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    testWidgets('the same instant renders the same pixels every time', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final t in const [3.0, 12.0, 14.0, 40.0]) {
          final first = await render(t);
          final second = await render(t);
          expect(listEquals(first, second), isTrue, reason: 't = $t');
        }
        // And different instants differ.
        expect(listEquals(await render(3), await render(40)), isFalse);
      });
    });
  });
}
