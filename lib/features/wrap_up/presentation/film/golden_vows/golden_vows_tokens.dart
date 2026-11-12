import 'package:flutter/painting.dart';

import '../marks/balloon_mark.dart';

/// Golden Vows' palette (docs/design/golden-vows/golden-vows-spec.md §1,
/// #346). Film-local like `SkyStoryColors`: the film is a fixed
/// composition that doesn't follow the app theme.
abstract final class GoldenVowsColors {
  static const ivory = Color(0xFFFAF5EC);
  static const ivoryDeep = Color(0xFFF2E8D6);
  static const paper = Color(0xFFFFFCF6);
  static const gold = Color(0xFFBE944E);
  static const goldLight = Color(0xFFE6CA92);
  static const goldDeep = Color(0xFF8A642C);
  static const ink = Color(0xFF423222);
  static const inkSoft = Color(0xFF867058);
  static const blush = Color(0xFFF0D2C8);
  static const peach = Color(0xFFFFCCA0);

  /// The page-turn flare's warm light (spec §3, at its 200/255 peak).
  static const flare = Color(0xFFFFD696);

  /// The balloon mark in gold (spec §4): Golden Vows' own styling of the
  /// Storyni balloon, in the intro, on the album cover and at the end.
  static const balloon = BalloonMarkStyle(
    envelope: [goldLight, gold, goldDeep],
    envelopeStops: [0, 0.55, 1],
    gores: Color(0x96FFFCF6),
    band: goldDeep,
    ropes: goldDeep,
    basket: goldDeep,
  );
}

/// Golden Vows' type (spec §1): Cormorant Garamond for names, labels and
/// lists, Pinyon Script for titles and handwriting. Pinyon has no Cyrillic,
/// so Russian script falls back glyph by glyph to Great Vibes, a close
/// formal script.
abstract final class GoldenVowsType {
  static const serifFamily = 'CormorantGaramond';
  static const scriptFamily = 'PinyonScript';
  static const scriptFallback = ['GreatVibes'];

  static TextStyle serif(
    double size, {
    required Color color,
    int weight = 500,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: serifFamily,
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    height: 1.2,
    fontVariations: [FontVariation.weight(weight.toDouble())],
  );

  static TextStyle script(double size, {required Color color}) => TextStyle(
    fontFamily: scriptFamily,
    fontFamilyFallback: scriptFallback,
    fontSize: size,
    color: color,
    height: 1.2,
  );
}
