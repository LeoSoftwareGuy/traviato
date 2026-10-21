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
}
