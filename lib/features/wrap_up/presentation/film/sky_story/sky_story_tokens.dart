import 'dart:ui';

/// Sky Story's palette (docs/design/sky-story/design-spec.md §2, #345).
/// Film-local like `WrapUpFilmColors`: the film is a fixed composition
/// that doesn't follow the app theme. Sky stops are sampled from the
/// reference stills, which the spec's values are rounded from.
abstract final class SkyStoryColors {
  /// The world's sky from the horizon (altitude 0) up into the night, as
  /// `(altitude px, colour)`. The camera climbs through it (`SkyWorld`).
  static const skyStops = <(double, Color)>[
    (0, Color(0xFFDB7A61)),
    (480, Color(0xFF9E5072)),
    (960, Color(0xFF6B3C67)),
    (1440, Color(0xFF452F62)),
    (1900, Color(0xFF322556)),
    (2400, Color(0xFF221E4D)),
    (2900, Color(0xFF1C1B47)),
    (3350, Color(0xFF191842)),
    (3800, Color(0xFF13163B)),
    (4600, Color(0xFF101435)),
  ];

  /// The flat night of the gather and outro, top to bottom.
  static const outroTop = Color(0xFF0B0D26);
  static const outroBottom = Color(0xFF0D112E);

  static const cloud = Color(0xFF8A5A8C);
  static const ember = Color(0xFFFFC870);
  static const star = Color(0xFFC9CCE0);

  static const balloonRedTop = Color(0xFFA81F33);
  static const balloonRed = Color(0xFFC8283A);
  static const balloonRedBottom = Color(0xFFE8483E);
  static const balloonMouth = Color(0xFFF2703F);
  static const balloonStripe = Color(0xFFEED9C0);
  static const balloonStripeShade = Color(0xFFD9C3B0);
  static const balloonRope = Color(0xFF2A1C1E);
  static const balloonBasket = Color(0xFF7A5238);
  static const burnerGlow = Color(0xFFFFD27A);
}
