final _whitespace = RegExp(r'\s+');

/// Words in a day note — whitespace-separated runs, as shown in the Journal
/// card's "N WORDS" footer and the note page's draft counter.
int countNoteWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(_whitespace).length;
}
