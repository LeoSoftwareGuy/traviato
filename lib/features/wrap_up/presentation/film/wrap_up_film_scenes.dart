/// The Wrap-Up Film's fixed scene table (docs/design/wrap-film-spec.md §1) —
/// absolute start times and durations in seconds, from a single 87.9s clock.
/// Fixed regardless of trip/library size: a 20-photo trip and a 200-photo
/// trip run identically, at different densities.
abstract class WrapUpFilmScenes {
  static const double total = 87.9;

  static const double dustStart = 0.0;
  static const double dustDur = 3.2;

  static const double invitationStart = 3.2;
  static const double invitationDur = 4.2;

  static const double bridge1Start = 7.4;
  static const double bridge1Dur = 3.4;

  /// M1–M8 start times, in order — `momentStarts[i]` is the `at` for
  /// `content.moments[i]`.
  static const List<double> momentStarts = [
    10.8, // M1
    16.3, // M2
    21.5, // M3
    36.1, // M4
    41.1, // M5
    46.1, // M6
    62.3, // M7
    67.3, // M8
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

  static const double flurry1Start = 26.6;
  static const double flurry1Dur = 6.3;

  static const double bridge2Start = 32.9;
  static const double bridge2Dur = 3.2;

  static const double flurry2Start = 51.1;
  static const double flurry2Dur = 7.0;

  static const double bridge3Start = 58.1;
  static const double bridge3Dur = 4.2;

  static const double footnoteStart = 72.3;
  static const double footnoteDur = 4.2;

  static const double unlockStart = 76.5;
  static const double unlockDur = 4.6;

  static const double keepsakeStart = 81.1;
  static const double keepsakeDur = 6.8;
}
