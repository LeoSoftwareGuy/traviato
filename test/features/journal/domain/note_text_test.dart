import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/domain/note_text.dart';

void main() {
  group('countNoteWords', () {
    test('counts whitespace-separated words', () {
      expect(countNoteWords('the lake  before\nthe buses'), 5);
    });

    test('is 0 for empty or blank text', () {
      expect(countNoteWords(''), 0);
      expect(countNoteWords('  \n '), 0);
    });
  });

  group('appendNoteText', () {
    test('joins the draft onto the entry with a single space', () {
      expect(
        appendNoteText('Great day.', 'Then the lake.'),
        'Great day. Then the lake.',
      );
      expect(
        appendNoteText('Great day.  \n', '  Then the lake. '),
        'Great day. Then the lake.',
      );
    });

    test('returns just the draft when there is no entry yet', () {
      expect(appendNoteText('', ' First words '), 'First words');
      expect(appendNoteText('   ', 'First words'), 'First words');
    });

    test('leaves the entry untouched for an empty draft', () {
      expect(appendNoteText('Great day.', '   '), 'Great day.');
    });
  });
}
