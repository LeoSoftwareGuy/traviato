/// The Wrap-Up Film's limits (#432), shared with the edge function:
/// `supabase/functions/generate_wrap_up/wrap_up_limits.json` is the source
/// of truth, and `wrap_up_limits_test.dart` fails if these disagree with it.
abstract final class WrapUpLimits {
  /// Photos a memory needs before its film unlocks.
  static const minPhotos = 15;

  /// The most photos a film shows — and so the most Always picks.
  static const maxFilmPhotos = 60;

  /// Notes a memory needs before its film unlocks (for the whole memory).
  static const minNotes = 1;

  /// The most note lines a film plays.
  static const maxNoteLines = 12;

  /// The most vibes the create-memory picker allows.
  static const maxVibes = 3;
}
