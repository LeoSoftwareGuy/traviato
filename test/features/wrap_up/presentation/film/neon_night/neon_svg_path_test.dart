import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_svg_path.dart';

void main() {
  test('lines and a closed shape', () {
    final path = parseNeonSvgPath('M76 226 L124 226 L120 244 L80 244 Z');
    expect(path.getBounds(), const Rect.fromLTRB(76, 226, 124, 244));
    expect(path.contains(const Offset(100, 235)), isTrue);
  });

  test('several sub-paths, and pairs after M are line-tos', () {
    final two = parseNeonSvgPath('M82 244 L88 262 M118 244 L112 262');
    expect(two.getBounds(), const Rect.fromLTRB(82, 244, 118, 262));
    final implicit = parseNeonSvgPath('M0,0 10,0 10,10');
    expect(implicit.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
  });

  test('cubic and quadratic curves', () {
    final q = parseNeonSvgPath('M24 78 Q100 96 176 78');
    final qb = q.getBounds();
    expect(qb.left, 24);
    expect(qb.right, 176);
    expect(qb.bottom, greaterThan(78));
    final c = parseNeonSvgPath('M100 12 C72 40 66 160 88 226');
    expect(c.getBounds().top, 12);
    expect(c.getBounds().bottom, 226);
  });

  test('anything outside the subset throws', () {
    expect(
      () => parseNeonSvgPath('M0 0 A5 5 0 0 1 10 10'),
      throwsFormatException,
    );
    expect(() => parseNeonSvgPath('M0 0 L5'), throwsFormatException);
    expect(() => parseNeonSvgPath('10 10'), throwsFormatException);
  });
}
