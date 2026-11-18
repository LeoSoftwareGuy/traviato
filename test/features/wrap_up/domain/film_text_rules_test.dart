import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/film_text_rules.dart';

void main() {
  group('readingTime (#399 T1)', () {
    test('0.8 s plus 1 s per 12 characters', () {
      expect(FilmTextRules.readingTime(''), 0.8);
      expect(FilmTextRules.readingTime('a' * 12), closeTo(1.8, 1e-9));
      // "боча пролил пиво": 16 characters, Cyrillic counted as one each.
      expect(
        FilmTextRules.readingTime('боча пролил пиво'),
        closeTo(0.8 + 16 / 12, 1e-9),
      );
    });

    test('surrounding spaces do not count', () {
      expect(
        FilmTextRules.readingTime('  our castle  '),
        FilmTextRules.readingTime('our castle'),
      );
    });
  });

  group('sentences', () {
    test('split at . ! ? … and line breaks, exactly as written', () {
      expect(
        FilmTextRules.sentences('Landed at 6. Ribs! Was it 4.5 kg? Wow… ok'),
        ['Landed at 6.', 'Ribs!', 'Was it 4.5 kg?', 'Wow…', 'ok'],
      );
      expect(FilmTextRules.sentences('first line\nsecond line\n\n'), [
        'first line',
        'second line',
      ]);
    });

    test('Russian', () {
      expect(
        FilmTextRules.sentences(
          'Ждём полтора метра рёбер: заказали 4,5 килограмма. '
          'Брюссель не меняется!',
        ),
        [
          'Ждём полтора метра рёбер: заказали 4,5 килограмма.',
          'Брюссель не меняется!',
        ],
      );
    });

    test('blank → none', () {
      expect(FilmTextRules.sentences('   '), isEmpty);
    });
  });

  group('leadingSentencesThatFit', () {
    bool upTo(int n, String s) => s.length <= n;

    test('as many whole sentences as fit, never a cut one', () {
      const note = 'One two. Three four. Five six seven eight nine.';
      expect(
        FilmTextRules.leadingSentencesThatFit(note, (s) => upTo(20, s)),
        'One two. Three four.',
      );
      expect(
        FilmTextRules.leadingSentencesThatFit(note, (s) => upTo(100, s)),
        note,
      );
    });

    test('not even the first sentence fits → null', () {
      expect(
        FilmTextRules.leadingSentencesThatFit(
          'A very long first sentence. Short.',
          (s) => upTo(10, s),
        ),
        isNull,
      );
    });
  });
}
