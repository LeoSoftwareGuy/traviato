import 'neon_beat.dart';

/// A Neon Night music track's beat map (#363, NEON_NIGHT_SPEC.md §2, §9):
/// its tempo, where its first downbeat sits in the file, and where its drop
/// is. The film lands the drop on the Finale cue, whatever the number of
/// chapters, by starting the track earlier or later.
class NeonTrack {
  const NeonTrack({
    required this.bpm,
    required this.firstDownbeat,
    required this.drop,
  }) : assert(drop > firstDownbeat, 'the drop comes after the first beat');

  /// The spec's reference track: 126 bpm, the first downbeat at 0, the
  /// drop on bar 28 (beat 108, 51.429 s).
  static const reference = NeonTrack(
    bpm: NeonBeat.referenceBpm,
    firstDownbeat: 0,
    drop: 108 * 60 / NeonBeat.referenceBpm,
  );

  final double bpm;

  /// Seconds into the file of the first downbeat.
  final double firstDownbeat;

  /// Seconds into the file of the drop.
  final double drop;

  /// The beat clock the film runs on with this track.
  NeonBeat get beat => NeonBeat(bpm);

  /// Whether the drop sits on a downbeat of the track's own grid (a whole
  /// number of bars after the first downbeat). If not, the drop can't
  /// land on a cue and its beats won't line up with the film's.
  bool get dropIsOnDownbeat {
    final bars = (drop - firstDownbeat) / beat.bar;
    return (bars - bars.roundToDouble()).abs() < 1e-3;
  }

  /// Where in the file the music is at film time [t], for a film whose
  /// drop is at [finaleCue]. Negative while the track hasn't started yet
  /// (the film opens before the track's first second).
  double positionAt(double t, {required double finaleCue}) =>
      t + drop - finaleCue;

  /// The film time the file starts playing at, for a film whose drop is at
  /// [finaleCue]. Negative when the film starts partway into the track.
  double startsAt({required double finaleCue}) => finaleCue - drop;
}
