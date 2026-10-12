import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_motion.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/presentation/widgets/guest_hero.dart';

const _wedding = Key('guest-polaroid-wedding');
const _birthday = Key('guest-polaroid-birthday');

Widget _hero({bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Scaffold(body: GuestHero()),
  ),
);

/// The drift transform applied to a polaroid: (rotation in degrees, dy).
({double degrees, double dy}) _drift(WidgetTester tester, Key key) {
  final transform = tester.widget<Transform>(
    find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
  );
  final m = transform.transform.storage;
  return (degrees: math.atan2(m[1], m[0]) * 180 / math.pi, dy: m[13]);
}

void main() {
  testWidgets('both polaroids start out of phase at their resting tilt', (
    tester,
  ) async {
    await tester.pumpWidget(_hero());

    final wedding = _drift(tester, _wedding);
    final birthday = _drift(tester, _birthday);
    expect(wedding.degrees, closeTo(-6, .01));
    expect(birthday.degrees, closeTo(6, .01));
    // Wedding at rest, birthday at the top of its float.
    expect(wedding.dy, closeTo(0, .01));
    expect(birthday.dy, closeTo(-AppMotion.polaroidDriftFloat, .01));
  });

  testWidgets('polaroids float and sway around their tilt, never past it', (
    tester,
  ) async {
    await tester.pumpWidget(_hero());

    final weddingDegrees = <double>[];
    final birthdayDegrees = <double>[];
    final weddingDy = <double>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      final wedding = _drift(tester, _wedding);
      final birthday = _drift(tester, _birthday);
      weddingDegrees.add(wedding.degrees);
      birthdayDegrees.add(birthday.degrees);
      weddingDy.add(wedding.dy);
      for (final dy in [wedding.dy, birthday.dy]) {
        expect(dy, inInclusiveRange(-AppMotion.polaroidDriftFloat - .01, .01));
      }
    }

    const sway = AppMotion.polaroidDriftSwayDegrees;
    for (final d in weddingDegrees) {
      expect(d, inInclusiveRange(-6 - sway - .01, -6 + sway + .01));
    }
    for (final d in birthdayDegrees) {
      expect(d, inInclusiveRange(6 - sway - .01, 6 + sway + .01));
    }
    // It actually moves: close to the full float and sway range.
    expect(weddingDy.reduce(math.min), lessThan(-6.5));
    expect(weddingDegrees.reduce(math.max), greaterThan(-6 + sway - .2));
    expect(weddingDegrees.reduce(math.min), lessThan(-6 - sway + .2));
  });

  testWidgets('reduced motion shows both polaroids still and tilted', (
    tester,
  ) async {
    await tester.pumpWidget(_hero(reduceMotion: true));

    for (var i = 0; i < 3; i++) {
      final wedding = _drift(tester, _wedding);
      final birthday = _drift(tester, _birthday);
      expect(wedding.degrees, closeTo(-6, .01));
      expect(wedding.dy, closeTo(0, .01));
      expect(birthday.degrees, closeTo(6, .01));
      expect(birthday.dy, closeTo(0, .01));
      await tester.pump(const Duration(seconds: 2));
    }
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
