import 'package:flutter/painting.dart';

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
  /// The closing mosaic's tile tints (over each photo): red gores, cream
  /// stripes, the sepia basket.
  static const mosaicRed = Color(0xFFC8283A);
  static const mosaicCream = Color(0xFFF6EBDD);
  static const mosaicBasket = Color(0xFF7A5238);

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

  // Pages (spec §2).
  static const eyebrowGold = Color(0xFFF2B865);
  static const headlineCream = Color(0xFFF6EBDD);
  static const polaroidPaper = Color(0xFFFDFAF4);
  static const noteCard = Color(0xFFF6F0E6);
  static const noteRule = Color(0xFFC9CFE0);
  static const ink = Color(0xFF2C2A55);
  static const signatureRed = Color(0xFFD2303E);
  static const tape = Color(0xB3F4C46A);
  static const badgeFill = Color(0xD93A3560);
  static const halo = Color(0xFFE8A060);
  static const pageShadow = Color(0x59000000);

  /// A photo that hasn't loaded (or never will): warm, never a white box.
  static const photoPlaceholderTop = Color(0xFFE8A060);
  static const photoPlaceholderBottom = Color(0xFFB45E6A);
}

/// Sky Story's type (spec §3), in canvas px. The fonts are bundled
/// (pubspec, OFL) so the film never waits on a download. Like
/// `WrapUpFilmText`, sizes are literal: the canvas scales as a whole.
abstract final class SkyStoryText {
  static const _serif = 'DMSerifDisplay';

  /// DM Serif Display has no Cyrillic; Playfair Display is the closest
  /// display serif that has it.
  static const _serifCyrillic = 'PlayfairDisplay';
  static const _sans = 'OpenSans';
  static const _hand = 'Caveat';

  static final _cyrillic = RegExp('[Ѐ-ӿ]');

  /// Whether [text] needs the Cyrillic serif. The whole string switches,
  /// so a title never mixes two serifs.
  static bool needsCyrillicSerif(String text) => _cyrillic.hasMatch(text);

  /// Titles and headlines, for [text].
  static TextStyle display(
    String text, {
    required double size,
    Color color = SkyStoryColors.headlineCream,
    double height = 1.0,
  }) {
    final cyrillic = needsCyrillicSerif(text);
    return TextStyle(
      fontFamily: cyrillic ? _serifCyrillic : _serif,
      fontSize: size,
      height: height,
      color: color,
      fontWeight: cyrillic ? FontWeight.w600 : FontWeight.w400,
      fontVariations: cyrillic ? const [FontVariation.weight(600)] : null,
    );
  }

  /// Eyebrows and the badge label; callers uppercase the text.
  static TextStyle label({
    double size = 28,
    Color color = SkyStoryColors.eyebrowGold,
    double trackingEm = 0.15,
    FontWeight weight = FontWeight.w700,
  }) => TextStyle(
    fontFamily: _sans,
    fontSize: size,
    height: 1.0,
    color: color,
    letterSpacing: size * trackingEm,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

  /// Handwriting: captions, notes, signatures, the subtitle.
  static TextStyle hand({
    required double size,
    Color color = SkyStoryColors.ink,
    bool bold = false,
    double height = 1.0,
  }) => TextStyle(
    fontFamily: _hand,
    fontSize: size,
    height: height,
    color: color,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    fontVariations: [FontVariation.weight(bold ? 700 : 400)],
  );
}
