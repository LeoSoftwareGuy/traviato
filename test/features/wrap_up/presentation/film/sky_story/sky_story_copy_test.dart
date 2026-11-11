import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_copy.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_fixture.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  SkyPage page({
    int firstDay = 1,
    int? lastDay,
    DateTime? endDate,
    int photoCount = 64,
    String? note = 'A note.',
    String? signature = 'Jonas',
  }) => SkyPage(
    firstDay: firstDay,
    lastDay: lastDay,
    date: DateTime(2026, 6, 12),
    endDate: endDate,
    photoCount: photoCount,
    headline: 'Lost, on purpose',
    hero: const SkyPhoto(id: 'h'),
    note: note,
    signature: signature,
  );

  group('the reference film, word for word (spec §7)', () {
    final copy = SkyStoryCopy.resolve(SkyStoryFixtures.lisbon, en, 'en');

    test('title page', () {
      expect(copy.title.eyebrow, 'A MEMORY STORY');
      expect(copy.title.title, 'Lisbon, together');
      expect(copy.title.subtitle, '12 – 14 June 2026 · Mari & Jonas');
    });

    test('day 1: count in the eyebrow, caption with the part of day', () {
      final day1 = copy.pages[0];
      expect(day1.eyebrow, 'DAY 1 · FRI 12 JUNE · 64 PHOTOS');
      expect(day1.headline, 'Lost, on purpose');
      expect(day1.heroCaption, 'Alfama · Fri morning');
      expect(day1.signature, '– Jonas');
      expect(day1.badgeCount, isNull);
    });

    test('day 2: the taped page moves its count onto the badge', () {
      final day2 = copy.pages[1];
      expect(day2.eyebrow, 'DAY 2 · SAT 13 JUNE');
      expect(day2.badgeCount, '71');
      expect(day2.badgeLabel, 'PHOTOS');
      expect(day2.heroCaption, 'Miradouro · Sat evening');
      expect(day2.signature, '– Mari');
    });

    test('day 3: no time taken, so the caption is the weekday', () {
      final day3 = copy.pages[2];
      expect(day3.eyebrow, 'DAY 3 · SUN 14 JUNE · 52 PHOTOS');
      expect(day3.heroCaption, 'Cascais · Sun');
    });
  });

  test('in Russian', () {
    final copy = SkyStoryCopy.resolve(SkyStoryFixtures.lisbonRu, ru, 'ru');
    expect(copy.title.eyebrow, 'ИСТОРИЯ ОДНОГО ВОСПОМИНАНИЯ');
    expect(copy.title.subtitle, '12 – 14 июня 2026 · Мари и Йонас');
    expect(copy.pages[0].eyebrow, 'ДЕНЬ 1 · ПТ 12 ИЮНЯ · 64 ФОТО');
    expect(copy.pages[0].heroCaption, 'Алфама · пт, утро');
    expect(copy.pages[1].badgeLabel, 'ФОТО');
    expect(copy.pages[1].heroCaption, 'Мирадоуру · сб, вечер');
  });

  group('eyebrow', () {
    test('a run of days', () {
      expect(
        SkyPageCopy.eyebrowFor(
          page(firstDay: 4, lastDay: 7, endDate: DateTime(2026, 6, 15)),
          en,
          'en',
        ),
        'DAYS 4–7 · 12–15 JUNE · 64 PHOTOS',
      );
    });

    test('one photo; and none counted leaves the count out', () {
      expect(
        SkyPageCopy.eyebrowFor(page(photoCount: 1), en, 'en'),
        'DAY 1 · FRI 12 JUNE · 1 PHOTO',
      );
      expect(
        SkyPageCopy.eyebrowFor(page(photoCount: 0), en, 'en'),
        'DAY 1 · FRI 12 JUNE',
      );
    });
  });

  group('caption', () {
    final date = DateTime(2026, 6, 12);

    test('place and part of day, either may be missing', () {
      expect(
        SkyPageCopy.captionFor(
          SkyPhoto(
            id: 'p',
            place: 'Alfama',
            takenAt: DateTime(2026, 6, 12, 15),
          ),
          date,
          en,
          'en',
        ),
        'Alfama · Fri afternoon',
      );
      expect(
        SkyPageCopy.captionFor(
          SkyPhoto(id: 'p', takenAt: DateTime(2026, 6, 12, 23)),
          date,
          en,
          'en',
        ),
        'Fri night',
      );
      expect(
        SkyPageCopy.captionFor(const SkyPhoto(id: 'p'), date, en, 'en'),
        'Fri',
      );
    });
  });

  group('note and signature', () {
    test('a blank note has no card and no signature', () {
      final copy = SkyPageCopy.resolve(
        page(note: '   '),
        SkyPageLayout.fan,
        en,
        'en',
      );
      expect(copy.note, isNull);
      expect(copy.signature, isNull);
    });

    test('a note without a name is unsigned', () {
      final copy = SkyPageCopy.resolve(
        page(signature: null),
        SkyPageLayout.fan,
        en,
        'en',
      );
      expect(copy.note, 'A note.');
      expect(copy.signature, isNull);
    });
  });

  test('date ranges', () {
    expect(
      SkyStoryCopy.dateRange(
        DateTime(2026, 6, 12),
        DateTime(2026, 6, 12),
        'en',
      ),
      '12 June 2026',
    );
    expect(
      SkyStoryCopy.dateRange(DateTime(2026, 5, 30), DateTime(2026, 6, 2), 'en'),
      '30 May – 2 June 2026',
    );
    expect(
      SkyStoryCopy.dateRange(
        DateTime(2026, 12, 30),
        DateTime(2027, 1, 2),
        'en',
      ),
      '30 December 2026 – 2 January 2027',
    );
  });

  test('a story with no names shows only the dates', () {
    final story = SkyStory(
      title: 'Paris',
      startDate: DateTime(2026, 6, 12),
      endDate: DateTime(2026, 6, 14),
      pages: [page()],
    );
    expect(
      SkyStoryCopy.resolve(story, en, 'en').title.subtitle,
      '12 – 14 June 2026',
    );
  });

  test('layouts: fan first, fly-out last, alternating between', () {
    String layouts(int n) => [
      for (var i = 0; i < n; i++) SkyPageLayout.forChapter(i, n).name,
    ].join(',');
    expect(layouts(1), 'fan');
    expect(layouts(2), 'fan,flyOut');
    expect(layouts(3), 'fan,taped,flyOut');
    expect(layouts(5), 'fan,taped,fan,taped,flyOut');
  });

  group('the ending', () {
    SkyOutroCopy outro(int count, AppLocalizations l10n, String locale) =>
        SkyStoryCopy.resolve(
          SkyStory(
            title: 'T',
            startDate: DateTime(2026, 6, 12),
            endDate: DateTime(2026, 6, 14),
            pages: SkyStoryFixtures.lisbon.pages,
            momentCount: count,
          ),
          l10n,
          locale,
        ).outro;

    test('the reference: 187 moments, the tagline', () {
      final copy = SkyStoryCopy.resolve(SkyStoryFixtures.lisbon, en, 'en');
      expect(copy.outro.moments, '187 moments');
      expect(copy.outro.tagline, 'Every memory, beautifully captured');
      expect(SkyOutroCopy.brand, 'STORYNI');
    });

    test('English plurals', () {
      expect(outro(1, en, 'en').moments, '1 moment');
      expect(outro(2, en, 'en').moments, '2 moments');
      expect(outro(0, en, 'en').moments, '0 moments');
    });

    test('Russian plurals', () {
      for (final (count, words) in const [
        (1, '1 момент'),
        (2, '2 момента'),
        (5, '5 моментов'),
        (21, '21 момент'),
        (187, '187 моментов'),
      ]) {
        expect(outro(count, ru, 'ru').moments, words);
      }
      expect(
        outro(3, ru, 'ru').tagline,
        'Каждое воспоминание бережно сохранено',
      );
    });
  });
}
