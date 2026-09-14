/// The Wrap-Up Film's scene timeline (docs/design/wrap-film-spec.md §1).
///
/// Computed per wrap-up rather than fixed: Flurry2 (fewer than 15 leftover
/// photos to show) and Unlock (no achievement earned) are cut from the
/// schedule entirely when they'd have nothing to show — their slot's
/// duration is skipped, and every later scene shifts back to fill the gap —
/// instead of playing an empty frame for their full allotted time. Every
/// other duration is fixed regardless of trip/library size: a 20-photo trip
/// and a 200-photo trip run at the same pace, just different densities.
class WrapUpFilmScenes {
  factory WrapUpFilmScenes({
    required bool hasFlurry2,
    required bool hasUnlock,
  }) {
    var cursor = 0.0;
    double take(double duration) {
      final start = cursor;
      cursor += duration;
      return start;
    }

    final dustStart = take(dustDur);
    final invitationStart = take(invitationDur);
    final bridge1Start = take(bridge1Dur);
    final m1 = take(momentDurations[0]);
    final m2 = take(momentDurations[1]);
    final m3 = take(momentDurations[2]);
    final flurry1Start = take(flurry1Dur);
    final bridge2Start = take(bridge2Dur);
    final m4 = take(momentDurations[3]);
    final m5 = take(momentDurations[4]);
    final m6 = take(momentDurations[5]);
    final flurry2Start = cursor;
    if (hasFlurry2) cursor += flurry2Dur;
    final bridge3Start = take(bridge3Dur);
    final m7 = take(momentDurations[6]);
    final m8 = take(momentDurations[7]);
    final footnoteStart = take(footnoteDur);
    final unlockStart = cursor;
    if (hasUnlock) cursor += unlockDur;
    final keepsakeStart = take(keepsakeDur);

    return WrapUpFilmScenes._(
      total: cursor,
      hasFlurry2: hasFlurry2,
      hasUnlock: hasUnlock,
      dustStart: dustStart,
      invitationStart: invitationStart,
      bridge1Start: bridge1Start,
      momentStarts: [m1, m2, m3, m4, m5, m6, m7, m8],
      flurry1Start: flurry1Start,
      bridge2Start: bridge2Start,
      flurry2Start: flurry2Start,
      bridge3Start: bridge3Start,
      footnoteStart: footnoteStart,
      unlockStart: unlockStart,
      keepsakeStart: keepsakeStart,
    );
  }

  const WrapUpFilmScenes._({
    required this.total,
    required this.hasFlurry2,
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

  // Fixed durations (docs/design/wrap-film-spec.md §1), same for every
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
  /// duration for `content.moments[i]`. Unaffected by hasFlurry2/hasUnlock.
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
  /// Shrinks by [flurry2Dur]/[unlockDur] when those scenes are cut.
  final double total;

  /// Whether Flurry2 has any leftover photos to show. `false` means its
  /// scene contributes 0 seconds to the schedule — [flurry2Start] is still a
  /// valid instant (where it *would* have started), just with nothing after
  /// it before Bridge3 begins.
  final bool hasFlurry2;

  /// Whether this trip earned an achievement. `false` means Unlock
  /// contributes 0 seconds to the schedule, same as [hasFlurry2] above.
  final bool hasUnlock;

  final double dustStart;
  final double invitationStart;
  final double bridge1Start;

  /// M1–M8 start times, in order — `momentStarts[i]` is the `at` for
  /// `content.moments[i]`.
  final List<double> momentStarts;

  final double flurry1Start;
  final double bridge2Start;
  final double flurry2Start;
  final double bridge3Start;
  final double footnoteStart;
  final double unlockStart;
  final double keepsakeStart;
}
