import '../film_eases.dart';

/// The only eases Neon Night uses (#363, NEON_NIGHT_SPEC.md §3.4), by the
/// spec's names. Ken Burns is linear.
abstract final class NeonEases {
  /// `easeOutCubic`.
  static const enter = FilmEases.power2Out;

  /// `easeOutBack`, s = 1.70158.
  static double pop(double p) => FilmEases.backOut(p);

  /// `easeOutExpo`.
  static const slam = FilmEases.expoOut;

  /// `easeInOutCubic`.
  static const scroll = FilmEases.power2InOut;

  static const kenBurns = FilmEases.linear;
}
