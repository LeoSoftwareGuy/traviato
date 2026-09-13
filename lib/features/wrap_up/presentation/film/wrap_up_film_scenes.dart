/// The Wrap-Up Film's fixed scene table (docs/design/wrap-film-spec.md §1) —
/// absolute start times and durations in seconds, from a single 87.9s clock.
/// Fixed regardless of trip/library size: a 20-photo trip and a 200-photo
/// trip run identically, at different densities.
abstract class WrapUpFilmScenes {
  // Bridges run +2.0s over docs/design/wrap-film-spec.md's original 3.4/3.2/4.2
  // (user feedback after watching the film: pure-text interludes disappeared
  // before they could be read). Every later start time below is the spec's
  // original value plus the cumulative bridge time added before it — the
  // scenes still run perfectly back-to-back (see wrap_up_film_scenes_test.dart).
  static const double total = 93.9;

  static const double dustStart = 0.0;
  static const double dustDur = 3.2;

  static const double invitationStart = 3.2;
  static const double invitationDur = 4.2;

  static const double bridge1Start = 7.4;
  static const double bridge1Dur = 5.4;

  /// M1–M8 start times, in order — `momentStarts[i]` is the `at` for
  /// `content.moments[i]`.
  static const List<double> momentStarts = [
    12.8, // M1
    18.3, // M2
    23.5, // M3
    40.1, // M4
    45.1, // M5
    50.1, // M6
    68.3, // M7
    73.3, // M8
  ];
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

  static const double flurry1Start = 28.6;
  static const double flurry1Dur = 6.3;

  static const double bridge2Start = 34.9;
  static const double bridge2Dur = 5.2;

  static const double flurry2Start = 55.1;
  static const double flurry2Dur = 7.0;

  static const double bridge3Start = 62.1;
  static const double bridge3Dur = 6.2;

  static const double footnoteStart = 78.3;
  static const double footnoteDur = 4.2;

  static const double unlockStart = 82.5;
  static const double unlockDur = 4.6;

  static const double keepsakeStart = 87.1;
  static const double keepsakeDur = 6.8;
}
