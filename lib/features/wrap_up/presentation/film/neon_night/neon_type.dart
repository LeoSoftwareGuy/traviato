import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Neon Night's type (#363, NEON_NIGHT_SPEC.md §3.2): Big Shoulders
/// Display for titles, JetBrains Mono for labels, times and notes. Big
/// Shoulders has no Cyrillic, so Russian falls back glyph by glyph to Fira
/// Sans Extra Condensed, a close condensed sans. All three are bundled.
abstract final class NeonType {
  static const displayFamily = 'BigShouldersDisplay';
  static const displayFallback = ['FiraSansExtraCondensed'];
  static const monoFamily = 'JetBrainsMono';

  /// Titles: caps, line-height 0.9.
  static TextStyle display(
    double size, {
    required int weight,
    Color? color,
    Paint? foreground,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    fontSize: size,
    // The static fallback picks its face by weight; the variable font by
    // its axis.
    fontWeight: _weight(weight),
    fontVariations: [FontVariation.weight(weight.toDouble())],
    color: foreground == null ? color : null,
    foreground: foreground,
    height: 0.9,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextStyle mono(
    double size, {
    required Color color,
    int weight = 500,
    double letterSpacing = 2,
  }) => TextStyle(
    fontFamily: monoFamily,
    fontSize: size,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation.weight(weight.toDouble())],
    color: color,
    letterSpacing: letterSpacing,
    height: 1.2,
  );

  static FontWeight _weight(int weight) =>
      FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)];

  /// The spec's auto-fit (§3.2): `min(maxSize, maxWidth / (chars × k))`
  /// on the longest line.
  static double fit(String text, double maxWidth, double maxSize, double k) {
    final chars = text
        .split('\n')
        .map((line) => line.runes.length)
        .fold(1, math.max);
    return math.min(maxSize, maxWidth / (chars * k));
  }
}
