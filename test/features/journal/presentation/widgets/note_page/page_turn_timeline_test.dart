import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/page_turn_timeline.dart';

/// Controller value for a moment [ms] into a timeline of [totalMs].
double _at(double ms, double totalMs) => ms / totalMs;

void main() {
  group('open (1170ms)', () {
    PageTurnFrame at(double ms) => PageTurnTimeline.open(_at(ms, 1170));

    test('starts closed: flat page, writing page fully shaded', () {
      expect(at(0).angle, 0);
      expect(at(0).writingShade, 1);
      expect(at(0).frontShade, 0);
      expect(at(0).showsFront, isTrue);
    });

    test('holds still for the first 120ms', () {
      expect(at(119), at(0));
    });

    test('ends fully turned with both shades settled', () {
      final end = at(1170);
      expect(end.angle, closeTo(-math.pi, 1e-9));
      expect(end.writingShade, closeTo(0, 1e-9));
      expect(end.frontShade, closeTo(1, 1e-9));
      expect(end.opacity, 1);
    });

    test('the writing-page shade is gone by 1070ms (950ms after the hold)', () {
      expect(at(1070).writingShade, closeTo(0, 1e-9));
      expect(at(1000).writingShade, greaterThan(0));
    });

    test('flips from front to back face exactly as the page passes 90°', () {
      for (var ms = 0.0; ms <= 1170; ms += 10) {
        final f = at(ms);
        expect(f.showsFront, f.angle > -math.pi / 2, reason: '@${ms}ms');
      }
      expect(at(300).showsFront, isTrue);
      expect(at(1100).showsFront, isFalse);
    });

    test('rotation never runs backwards', () {
      var last = 0.0;
      for (var ms = 0.0; ms <= 1170; ms += 5) {
        final angle = at(ms).angle;
        expect(angle, lessThanOrEqualTo(last + 1e-9));
        last = angle;
      }
    });
  });

  group('close (880ms)', () {
    PageTurnFrame at(double ms) => PageTurnTimeline.close(_at(ms, 880));

    test('starts where the open ended, with no hold', () {
      expect(at(0).angle, closeTo(-math.pi, 1e-9));
      expect(at(0).writingShade, 0);
      expect(at(0).frontShade, 1);
      expect(at(20).angle, greaterThan(-math.pi));
    });

    test('lands flat at 850ms, shades reversed, then fades out by 880ms', () {
      expect(at(850).angle, closeTo(0, 1e-9));
      expect(at(850).writingShade, closeTo(1, 1e-9));
      expect(at(850).frontShade, closeTo(0, 1e-9));
      expect(at(850).opacity, 1);
      expect(at(880).opacity, closeTo(0, 1e-9));
    });
  });
}
