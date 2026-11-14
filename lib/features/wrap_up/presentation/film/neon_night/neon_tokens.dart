import 'package:flutter/painting.dart';

/// Neon Night's palette (#363, NEON_NIGHT_SPEC.md §3.1). Film-local like
/// `GoldenVowsColors`: the film is a fixed composition that doesn't follow
/// the app theme.
abstract final class NeonColors {
  static const black = Color(0xFF05030A);
  static const pink = Color(0xFFFF2BD6);
  static const cyan = Color(0xFF22F2FF);
  static const green = Color(0xFFB6FF2E);
  static const violet = Color(0xFF9B5CFF);

  /// Placeholder photos only.
  static const orange = Color(0xFFFF7A2B);

  /// Plan rows that aren't done.
  static const grey = Color(0xFF4A4458);

  /// The haze blobs' colour (drawn at α 0.55).
  static const haze = Color(0xFF6A2FB8);

  /// Lit neon text fill: the hot core of a tube.
  static const tintCyan = Color(0xFFD9FDFF);
  static const tintPink = Color(0xFFFFD6F6);
  static const tintViolet = Color(0xFFEBDDFF);
  static const tintGreen = Color(0xFFF0FFD6);

  /// Stats and the closing line.
  static const body = Color(0xFFE7E3F2);

  static const white = Color(0xFFFFFFFF);

  /// The accent of chapter [index] (from 0): cyan, violet, green, pink,
  /// then cyan again.
  static Color chapterAccent(int index) => _accents[index % _accents.length];

  static const _accents = [cyan, violet, green, pink];
}
