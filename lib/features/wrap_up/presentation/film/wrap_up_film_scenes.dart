import '../../domain/entities/wrap_up_entity.dart';

/// The Wrap-Up Film's scene timeline (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §1).
///
/// Computed per wrap-up rather than fixed: a scene with nothing to show is
/// cut from the schedule entirely — its slot's duration is skipped and
/// every later scene shifts back to fill the gap — instead of playing an
/// empty frame for its full allotted time. Every scene that does play
/// keeps its fixed duration regardless of trip/library size: a 20-photo
/// trip and a 200-photo trip run at the same pace, just different
/// densities.
///
/// Persistent chrome (specks, washes, vignette, grain, letterbox) is
/// anchored to scene starts, not absolute times, so it follows whatever
/// schedule this produces.
class WrapUpFilmScenes {
  factory WrapUpFilmScenes({
    required bool hasFlurry2,
    required bool hasUnlock,
    bool hasFlurry1 = true,
    int momentCount = 8,
    bool hasBridge2 = true,
    bool hasBridge3 = true,
  }) {
    assert(momentCount >= 0 && momentCount <= 8, 'at most 8 moments');
    var cursor = 0.0;
    double take(double duration) {
      final start = cursor;
      cursor += duration;
      return start;
    }

    double takeIf(bool plays, double duration) {
      final start = cursor;
      if (plays) cursor += duration;
      return start;
    }

    final momentStarts = <double>[];
    void takeMoments(int from, int to) {
      for (var i = from; i < to && i < momentCount; i++) {
        momentStarts.add(take(momentDurations[i]));
      }
    }

    final dustStart = take(dustDur);
    final invitationStart = take(invitationDur);
    final bridge1Start = take(bridge1Dur);
    takeMoments(0, 3);
    final flurry1Start = takeIf(hasFlurry1, flurry1Dur);
    final bridge2Start = takeIf(hasBridge2, bridge2Dur);
    takeMoments(3, 6);
    final flurry2Start = takeIf(hasFlurry2, flurry2Dur);
    final bridge3Start = takeIf(hasBridge3, bridge3Dur);
    takeMoments(6, 8);
    final footnoteStart = take(footnoteDur);
    final unlockStart = takeIf(hasUnlock, unlockDur);
    final keepsakeStart = take(keepsakeDur);

    return WrapUpFilmScenes._(
      total: cursor,
      hasFlurry1: hasFlurry1,
      hasFlurry2: hasFlurry2,
      hasBridge2: hasBridge2,
      hasBridge3: hasBridge3,
      hasUnlock: hasUnlock,
      dustStart: dustStart,
      invitationStart: invitationStart,
      bridge1Start: bridge1Start,
      momentStarts: List.unmodifiable(momentStarts),
      flurry1Start: flurry1Start,
      bridge2Start: bridge2Start,
      flurry2Start: flurry2Start,
      bridge3Start: bridge3Start,
      footnoteStart: footnoteStart,
      unlockStart: unlockStart,
      keepsakeStart: keepsakeStart,
    );
  }

  /// The schedule for [wrapUp]'s resolved plan (#151): one slot per moment
  /// that exists, a Flurry only when it has photos, and Bridge2/Bridge3
  /// only when moments follow them (M4 / M7). A pre-#151 wrap-up
  /// (`cut == null`) keeps the original schedule: 8 moment slots, Flurry1
  /// always, all three bridges.
  factory WrapUpFilmScenes.forWrapUp(WrapUpEntity wrapUp) {
    final hasUnlock = wrapUp.unlock != null;
    final hasFlurry2 = wrapUp.flurry2Photos.isNotEmpty;
    if (wrapUp.cut == null) {
      return WrapUpFilmScenes(hasFlurry2: hasFlurry2, hasUnlock: hasUnlock);
    }
    final momentCount = wrapUp.moments.length.clamp(0, 8);
    return WrapUpFilmScenes(
      hasFlurry1: wrapUp.flurry1Photos.isNotEmpty,
      hasFlurry2: hasFlurry2,
      hasUnlock: hasUnlock,
      momentCount: momentCount,
      hasBridge2: momentCount > 3,
      hasBridge3: momentCount > 6,
    );
  }

  const WrapUpFilmScenes._({
    required this.total,
    required this.hasFlurry1,
    required this.hasFlurry2,
    required this.hasBridge2,
    required this.hasBridge3,
    required this.hasUnlock,
    required this.dustStart,
    required this.invitationStart,
    required this.bridge1Start,
    required this.momentStarts,
    required this.flurry1Start,
    required this.bridge2Start,
    required this.flurry2Start,
    required this.bridge3Start,
    required this.footnoteStart,
    required this.unlockStart,
    required this.keepsakeStart,
  });

  // Fixed durations (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §1), same for every
  // wrap-up. Bridges run +4.0s over the spec's original 3.4/3.2/4.2 —
  // twice-revised after watching real playback: pure-text interludes need
  // real time to read, and (see WrapUpFilmBridge) the fade-out is tied to
  // each bridge's own duration, so extending only the schedule slot without
  // also retuning the fade would have added dead air, not reading time.
  static const double dustDur = 3.2;
  static const double invitationDur = 4.2;
  static const double bridge1Dur = 7.4;
  static const double bridge2Dur = 7.2;
  static const double bridge3Dur = 8.2;

  /// M1–M8 durations, in order — `momentDurations[i]` is the on-screen
  /// duration for `content.moments[i]`. Never compressed: a moment needs
  /// its full length for the flip and a readable caption (#151).
  static const List<double> momentDurations = [
    5.5, // M1
    5.2, // M2
    5.1, // M3
    5.0, // M4
    5.0, // M5
    5.0, // M6
    5.0, // M7
    5.0, // M8
  ];

  static const double flurry1Dur = 6.3;
  static const double flurry2Dur = 7.0;
  static const double footnoteDur = 4.2;
  static const double unlockDur = 4.6;
  static const double keepsakeDur = 6.8;

  /// Total film length in seconds — the loop's `AnimationController` duration.
  /// Shrinks by each cut scene's duration.
  final double total;

  /// Whether each optional scene plays. `false` means that scene
  /// contributes 0 seconds to the schedule — its start is still a valid
  /// instant (where it *would* have started), just with the next scene
  /// beginning at that same instant.
  final bool hasFlurry1;
  final bool hasFlurry2;
  final bool hasBridge2;
  final bool hasBridge3;

  /// Whether this trip earned an achievement — cut the same way as above.
  final bool hasUnlock;

  final double dustStart;
  final double invitationStart;
  final double bridge1Start;

  /// Start times for the moments that play, in order — `momentStarts[i]`
  /// is the `at` for `content.moments[i]`. Up to 8; a pre-#151 wrap-up
  /// always gets all 8 slots.
  final List<double> momentStarts;

  final double flurry1Start;
  final double bridge2Start;
  final double flurry2Start;
  final double bridge3Start;
  final double footnoteStart;
  final double unlockStart;
  final double keepsakeStart;
}
