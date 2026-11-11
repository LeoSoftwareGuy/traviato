import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_fixture.dart';
import 'package:traviato/features/wrap_up/presentation/pages/sky_story_preview_page.dart';
import 'package:traviato/l10n/app_localizations.dart';

/// A page with as little as a page can have: no place, no time, no other
/// photos, no note.
SkyPage _barePage(int day) => SkyPage(
  firstDay: day,
  date: DateTime(2026, 6, 11 + day),
  photoCount: 0,
  headline: 'An extraordinarily long headline that cannot fit on one line',
  hero: SkyPhoto(id: 'missing_$day'),
);

SkyStory _story(List<SkyPage> pages) => SkyStory(
  title: 'A title long enough to need all three of its lines, and then more',
  startDate: DateTime(2026, 6, 12),
  endDate: DateTime(2026, 6, 11 + pages.length),
  pages: pages,
);

Future<void> _playThrough(
  WidgetTester tester,
  SkyStory story, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: SkyStoryCanvas(story: story, photo: (_) => null),
    ),
  );
  // Every quarter second, through every beat of every page.
  for (var i = 0; i < 4 * 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: 't=${i / 4}');
  }
}

void main() {
  testWidgets('1 to 5 bare pages, no photos loaded, play through', (
    tester,
  ) async {
    for (var n = 1; n <= 5; n++) {
      await _playThrough(
        tester,
        _story([for (var d = 1; d <= n; d++) _barePage(d)]),
      );
    }
  });

  testWidgets('long notes and many photos play through, in Russian too', (
    tester,
  ) async {
    final long = SkyPage(
      firstDay: 1,
      lastDay: 4,
      date: DateTime(2026, 6, 12),
      endDate: DateTime(2026, 6, 15),
      photoCount: 300,
      headline: 'Four days',
      hero: const SkyPhoto(id: 'h', place: 'Somewhere far'),
      extras: [for (var i = 0; i < 9; i++) SkyPhoto(id: 'x$i')],
      note: List.filled(40, 'word').join(' '),
      signature: 'Mari',
    );
    await _playThrough(tester, _story([long, long, long, long]));
    await _playThrough(
      tester,
      SkyStoryFixtures.lisbonRu,
      locale: const Locale('ru'),
    );
  });

  testWidgets('the ending plays with tiles that never load', (tester) async {
    await _playThrough(
      tester,
      SkyStory(
        title: 'Tiles',
        startDate: DateTime(2026, 6, 12),
        endDate: DateTime(2026, 6, 13),
        pages: [_barePage(1), _barePage(2)],
        momentCount: 1,
        mosaicPhotoIds: [for (var i = 0; i < 80; i++) 'gone_$i'],
      ),
    );
  });

  testWidgets('the preview switches the film to Russian', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkyStoryPreviewPage(),
      ),
    );
    expect(find.text('EN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sky-story-language')));
    await tester.pump();
    expect(find.text('RU'), findsOneWidget);
    expect(find.byType(SkyStoryCanvas), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });
}
