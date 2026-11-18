import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_handwriting.dart';

/// 10 px a character: easy widths to reason about.
double _measure(String s) => s.length * 10.0;

void main() {
  group('wrapWords', () {
    test('fills each line greedily up to the width', () {
      expect(
        wrapWords('one two three four five', 100, _measure),
        ['one two', 'three four', 'five'],
      );
    });

    test('a short note is one line; an empty one is none', () {
      expect(wrapWords('  hello   there ', 200, _measure), ['hello there']);
      expect(wrapWords('   ', 200, _measure), isEmpty);
    });

    test('never cut: every word stays, with no "…" (#399)', () {
      final lines = wrapWords(
        'aaa bbb ccc ddd eee fff ggg hhh, iii jjj',
        70,
        _measure,
      );
      expect(lines.join(' '), 'aaa bbb ccc ddd eee fff ggg hhh, iii jjj');
      expect(lines.join(), isNot(contains('…')));
    });

    test('a word wider than the line keeps a line of its own', () {
      expect(
        wrapWords('a extraordinarily b', 60, _measure),
        ['a', 'extraordinarily', 'b'],
      );
    });
  });

  group('fitsWords', () {
    test('fits within the lines and the width', () {
      expect(fitsWords('one two three', 100, _measure, maxLines: 2), isTrue);
      expect(
        fitsWords('one two three four five', 100, _measure, maxLines: 2),
        isFalse,
      );
    });

    test('a word wider than the line never fits; nothing never does', () {
      expect(fitsWords('extraordinarily', 60, _measure, maxLines: 3), isFalse);
      expect(fitsWords('  ', 60, _measure, maxLines: 3), isFalse);
    });
  });

  test('writeOnSchedule: a steady hand, a pause between lines', () {
    final schedule = writeOnSchedule([560, 280], 10);
    expect(schedule[0].start, 10);
    expect(schedule[0].end, closeTo(11, 1e-9));
    expect(schedule[1].start, closeTo(11.35, 1e-9));
    expect(schedule[1].end, closeTo(11.85, 1e-9));
  });
}
