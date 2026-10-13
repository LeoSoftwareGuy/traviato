import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/dictation_insertion.dart';

TextEditingValue _at(String text, int caret) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret),
);

void main() {
  test('into an empty field: just the words, caret after them', () {
    final insertion = DictationInsertion.at(_at('', 0));
    final value = insertion.apply('the lake');
    expect(value.text, 'the lake');
    expect(value.selection.baseOffset, 8);
    expect(insertion.rangeOf('the lake'), const TextRange(start: 0, end: 8));
  });

  test('joins with a single space after text without trailing whitespace', () {
    final insertion = DictationInsertion.at(_at('Woke early.', 11));
    expect(insertion.apply('Then the lake').text, 'Woke early. Then the lake');
    expect(
      insertion.rangeOf('Then the lake'),
      const TextRange(start: 12, end: 25),
    );
  });

  test('adds no extra space when the text already ends in whitespace', () {
    final insertion = DictationInsertion.at(_at('Woke early.\n', 12));
    expect(insertion.apply('Then').text, 'Woke early.\nThen');
  });

  test('inserts at the caret, keeping the text after it', () {
    final insertion = DictationInsertion.at(_at('Woke early. Swam.', 11));
    final value = insertion.apply('Coffee');
    expect(value.text, 'Woke early. Coffee Swam.');
    expect(value.selection.baseOffset, 18);
  });

  test('each update replaces the session words (cumulative transcript)', () {
    final insertion = DictationInsertion.at(_at('Hi', 2));
    insertion.apply('the');
    expect(insertion.apply('the lake was').text, 'Hi the lake was');
  });

  test('no valid selection: appends at the end', () {
    final insertion = DictationInsertion.at(
      const TextEditingValue(text: 'Woke early.'),
    );
    expect(insertion.apply('Then').text, 'Woke early. Then');
  });

  test('empty words leave the text as it was', () {
    final insertion = DictationInsertion.at(_at('Woke', 4));
    expect(insertion.apply('  ').text, 'Woke');
    expect(insertion.rangeOf(''), TextRange.empty);
  });
}
