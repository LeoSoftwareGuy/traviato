final _whitespace = RegExp(r'\s+');

/// Words in a day note — whitespace-separated runs, as shown in the Journal
/// card's "N WORDS" footer and the note page's draft counter.
int countNoteWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(_whitespace).length;
}

/// The note page only ever appends (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
/// §5): the existing entry is never edited there. Joins with a single space,
/// or returns just [draft] when there's no entry yet.
String appendNoteText(String existing, String draft) {
  final base = existing.trimRight();
  final addition = draft.trim();
  if (addition.isEmpty) return existing;
  if (base.isEmpty) return addition;
  return '$base $addition';
}
