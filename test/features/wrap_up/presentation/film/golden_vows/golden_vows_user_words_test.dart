import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/l10n/app_localizations.dart';

/// Golden Vows shows the user's words whole, long enough to read (#399).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    for (final (family, asset) in const [
      ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
      ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
      ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  String shown(TextPainter painter) => (painter.text! as TextSpan).text!;

  group("a photo's note (T1)", () {
    test('a short note shows whole on its card', () {
      final note = fitGvNote('The best day of our lives')!;
      expect(shown(note), 'The best day of our lives');
      expect(note.didExceedMaxLines, isFalse);
      expect(note.height, lessThanOrEqualTo(GvHeroTexts.noteMaxHeight));
      note.dispose();
    });

    test('Cyrillic, mixed with English, fits the same way (T5)', () {
      final note = fitGvNote('Наш день · our castle')!;
      expect(shown(note), 'Наш день · our castle');
      note.dispose();
    });

    test('too long: its first whole sentences, never "…"', () {
      final long = [
        'We said yes.',
        for (var i = 0; i < 10; i++)
          'Then everyone cried and danced until the band went home.',
      ].join(' ');
      final note = fitGvNote(long)!;
      expect(shown(note), startsWith('We said yes.'));
      expect(shown(note), endsWith('.'));
      expect(shown(note), isNot(contains('…')));
      expect(note.didExceedMaxLines, isFalse);
      note.dispose();
    });

    test('not even one sentence fits: no note', () {
      expect(fitGvNote(List.filled(80, 'word').join(' ')), isNull);
    });
  });

  group('reading time (T1)', () {
    test("a photo page lies open until its note is read", () {
      expect(GoldenVowsTimeline.heroDwellFor(null), 3.0);
      expect(GoldenVowsTimeline.heroDwellFor('Yes!'), 3.0);
      final note = 'a' * 84; // 0.8 + 7 = 7.8 s
      expect(
        GoldenVowsTimeline.heroDwellFor(note),
        closeTo(7.8 - GoldenVowsTimeline.turnDur, 1e-9),
      );
      final story = GoldenVowsStory(
        names: 'Anna & Marco',
        date: DateTime(2026, 6, 14),
        heroes: [GvHero(photoId: 'a', note: note)],
      );
      final long = GoldenVowsTimeline.forStory(story).total;
      final short = GoldenVowsTimeline.forStory(
        GoldenVowsStory(
          names: 'Anna & Marco',
          date: DateTime(2026, 6, 14),
          heroes: const [GvHero(photoId: 'a', note: 'Yes!')],
        ),
      ).total;
      expect(long - short, closeTo(7.8 - 1.25 - 3.0, 1e-9));
    });
  });

  test('the heart line leaves out a zero (T4)', () {
    final none = GoldenVowsStory(
      names: 'Anna & Marco',
      date: DateTime(2026, 6, 14),
      dayCount: 0,
      moments: 0,
    );
    expect(GvAlbumTexts.heartLineFor(none, en), isNull);
    final some = GoldenVowsStory(
      names: 'Anna & Marco',
      date: DateTime(2026, 6, 14),
      moments: 12,
      dayCount: 0,
    );
    expect(GvAlbumTexts.heartLineFor(some, en), en.goldenVows_moments(12));
  });
}
