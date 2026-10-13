import 'package:flutter/services.dart';

final _whitespaceEnd = RegExp(r'\s$');
final _whitespaceStart = RegExp(r'^\s');

/// Where one dictation session's words go in the draft: at the caret when
/// the session started (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §4).
/// The recogniser reports a cumulative transcript, so every update
/// replaces the session's words in place rather than appending.
class DictationInsertion {
  DictationInsertion._(this._prefix, this._suffix);

  /// Anchors at [value]'s caret — or the end of the text when there's no
  /// valid selection. A selected range is replaced by the dictation.
  factory DictationInsertion.at(TextEditingValue value) {
    final text = value.text;
    final selection = value.selection;
    if (!selection.isValid) return DictationInsertion._(text, '');
    return DictationInsertion._(
      text.substring(0, selection.start),
      text.substring(selection.end),
    );
  }

  final String _prefix;
  final String _suffix;

  /// One space before the words unless the text before them already ends
  /// in whitespace (or there is none).
  String get _lead =>
      _prefix.isEmpty || _whitespaceEnd.hasMatch(_prefix) ? '' : ' ';

  String _trail(String words) =>
      words.isEmpty || _suffix.isEmpty || _whitespaceStart.hasMatch(_suffix)
      ? ''
      : ' ';

  /// The draft with [words] in place, caret just after them.
  TextEditingValue apply(String words) {
    final words0 = words.trim();
    final inserted = words0.isEmpty ? '' : '$_lead$words0${_trail(words0)}';
    final caret = _prefix.length + inserted.length - _trail(words0).length;
    return TextEditingValue(
      text: '$_prefix$inserted$_suffix',
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// The range [words] occupies in [apply]'s text — the not-yet-final
  /// span shown in lighter ink.
  TextRange rangeOf(String words) {
    final words0 = words.trim();
    if (words0.isEmpty) return TextRange.empty;
    final start = _prefix.length + _lead.length;
    return TextRange(start: start, end: start + words0.length);
  }
}
