import 'dart:math' as math;

/// Neon Night's beat clock (#363, docs/design/neon-night/NEON_NIGHT_SPEC.md
/// §2). Every scene is laid out in beats; this turns beats into film
/// seconds and back, so a track with another [bpm] only rescales the film.
///
/// Beat 0 is the film's first downbeat, at T = 0.
class NeonBeat {
  const NeonBeat([this.bpm = referenceBpm]) : assert(bpm > 0, 'bpm: $bpm');

  /// The reference track's tempo.
  static const double referenceBpm = 126;

  /// The film is rendered (and exported) at 30 frames a second.
  static const int fps = 30;

  /// How fast the kick envelope dies after each beat, s.
  static const double kickDecay = 0.14;

  final double bpm;

  /// One beat, s: 0.476190 at 126 bpm.
  double get beat => 60 / bpm;

  /// One 4/4 bar, s.
  double get bar => 4 * beat;

  double beatToSec(num beats) => beats * beat;

  double secToBeat(double seconds) => seconds / beat;

  /// The global kick envelope at film time [t]: 1 on every beat, ~0.03 by
  /// the next one.
  double beatEnv(double t) {
    final b = t / beat;
    final f = b - b.floorToDouble();
    return math.exp(-f * beat / kickDecay);
  }

  /// A one-shot hit envelope: 0 before [at], 1 on it, decaying with time
  /// constant [tau] (s) after.
  static double flare(double t, double at, double tau) =>
      t < at ? 0 : math.exp(-(t - at) / tau);

  /// The frame film time [t] falls in. Glitch and grain are quantised to
  /// it, so they change once per frame on every device.
  static int frameAt(double t) => (t * fps + 1e-9).floor();
}
