/// How the films show the user's own words (#399): long enough to read,
/// never cut short.
abstract final class FilmTextRules {
  /// Seconds a caption or note must stay readable on screen (#399 T1):
  /// 0.8 s plus 1 s for every 12 characters.
  static double readingTime(String text) => 0.8 + text.trim().runes.length / 12;

  static final _sentenceEnd = RegExp(r'(?<=[.!?…])\s+|\n+');

  /// [text] split into its sentences, exactly as written (#383): each
  /// ends at `.`, `!`, `?` or `…` followed by a space, or at a line
  /// break. Empty pieces are dropped; nothing is reworded.
  static List<String> sentences(String text) => [
    for (final piece in text.trim().split(_sentenceEnd))
      if (piece.trim().isNotEmpty) piece.trim(),
  ];

  /// The longest run of [text]'s first whole sentences that [fits], or
  /// null when not even the first one does. Cuts only between sentences,
  /// so what is shown is always the user's exact words.
  static String? leadingSentencesThatFit(
    String text,
    bool Function(String) fits,
  ) {
    final all = sentences(text);
    String? best;
    for (var n = 1; n <= all.length; n++) {
      final candidate = all.take(n).join(' ');
      if (!fits(candidate)) break;
      best = candidate;
    }
    return best;
  }
}
