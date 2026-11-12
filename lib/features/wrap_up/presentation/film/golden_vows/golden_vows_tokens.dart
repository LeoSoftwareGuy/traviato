import 'package:flutter/painting.dart';

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
}
