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
    Color? color,
    Paint? foreground,
    int weight = 500,
    double letterSpacing = 2,
    double height = 1.2,
  }) => TextStyle(
    fontFamily: monoFamily,
    fontSize: size,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation.weight(weight.toDouble())],
    color: foreground == null ? color : null,
    foreground: foreground,
    letterSpacing: letterSpacing,
    height: height,
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

  /// A title over 10 characters with 2+ words goes on 2 lines, split at
  /// the word boundary nearest its middle (§5.3).
  static String splitTitle(String title) {
    final words = title.split(' ');
    if (title.runes.length <= 10 || words.length < 2) return title;
    final middle = title.length / 2;
    var best = 1;
    var bestDistance = double.infinity;
    var at = 0;
    for (var i = 1; i < words.length; i++) {
      at += words[i - 1].length + 1;
      final distance = (at - 1 - middle).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return [
      words.take(best).join(' '),
      words.skip(best).join(' '),
    ].join('\n');
  }
}
