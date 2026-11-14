import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/film_eases.dart';

void main() {
  test('every ease runs 0 → 1', () {
    for (final ease in <double Function(double)>[
      FilmEases.linear,
      FilmEases.power1In,
      FilmEases.power1Out,
      FilmEases.power1InOut,
      FilmEases.power2In,
      FilmEases.power2Out,
      FilmEases.power2InOut,
      FilmEases.power3In,
      FilmEases.power3Out,
      FilmEases.power3InOut,
      FilmEases.sineInOut,
      FilmEases.sineOut,
      FilmEases.backOut,
      FilmEases.expoOut,
    ]) {
      expect(ease(0), closeTo(0, 1e-12));
      expect(ease(1), closeTo(1, 1e-12));
    }
  });

  test('GSAP powers: power1 is quadratic, power2 cubic, power3 quartic', () {
    expect(FilmEases.power1In(0.5), 0.25);
    expect(FilmEases.power2In(0.5), 0.125);
    expect(FilmEases.power3In(0.5), 0.0625);
    expect(FilmEases.power2Out(0.5), 0.875);
    expect(FilmEases.power2InOut(0.25), 0.0625);
    expect(FilmEases.power2InOut(0.5), 0.5);
    expect(FilmEases.sineInOut(0.5), closeTo(0.5, 1e-12));
  });

  test('back.out overshoots, then settles', () {
    expect(FilmEases.backOut(0.7, 2), greaterThan(1));
  });

  test('at() clamps and eases a tween', () {
    expect(FilmEases.at(0, 1, 2), 0);
    expect(FilmEases.at(5, 1, 2), 1);
    expect(FilmEases.at(2, 1, 2, FilmEases.linear), 0.5);
  });

  test('expoOut is easeOutExpo: 1 − 2^(−10p)', () {
    expect(FilmEases.expoOut(0.1), 0.5);
    expect(FilmEases.expoOut(0.5), closeTo(1 - 1 / 32, 1e-12));
  });
}
