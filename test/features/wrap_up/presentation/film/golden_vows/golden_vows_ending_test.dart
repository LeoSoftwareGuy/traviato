import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_ambient.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_ending.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_ending_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const e = 60.95;
  final ending = GoldenVowsEnding(
    GoldenVowsAmbient(GoldenVowsTimeline.reference()),
  );

  setUpAll(() async {
    await initializeDateFormatting('ru');
    for (final (family, asset) in const [
      ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
      ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
      ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  test('starts at e', () {
    expect(ending.start, closeTo(e, 1e-9));
    expect(ending.visibleAt(e - 0.01), isFalse);
    expect(ending.visibleAt(e), isTrue);
  });

  test('the balloon comes down to 560, then bobs 560 ↔ 530 on 3 s legs', () {
    expect(ending.balloonY(e), closeTo(-420, 1e-9));
    expect(ending.balloonY(e + 2.6), closeTo(560, 1e-9));
    // Lowest-on-screen-top (highest balloon) at ~66.6 s, as measured.
    expect(ending.balloonY(e + 5.6), closeTo(530, 1e-9));
    expect(ending.balloonY(e + 8.6), closeTo(560, 1e-9));
    expect(ending.balloonY(e + 4.1), closeTo(545, 1e-9));
  });

  test('"Storyni" tightens 40 → 8 and sharpens from e + 1.4 over 2 s', () {
    expect(ending.wordmark(e + 1.4), closeTo(0, 1e-9));
    expect(ending.wordmarkSpacing(e + 1.4), closeTo(40, 1e-9));
    expect(ending.wordmarkBlur(e + 1.4), closeTo(10, 1e-9));
    expect(ending.wordmark(e + 3.4), closeTo(1, 1e-9));
    expect(ending.wordmarkSpacing(e + 3.4), closeTo(8, 1e-9));
    expect(ending.wordmarkBlur(e + 3.4), closeTo(0, 1e-9));
  });

  test('the rule grows from e + 2.4; the line rises from e + 2.7', () {
    expect(ending.ruleGrown(e + 2.4), closeTo(0, 1e-9));
    expect(ending.ruleGrown(e + 3.8), closeTo(1, 1e-9));
    final before = ending.lineAt(e + 2.7);
    expect(before.top, closeTo(1265, 1e-9));
    expect(before.opacity, closeTo(0, 1e-9));
    final after = ending.lineAt(e + 3.9);
    expect(after.top, closeTo(1245, 1e-9));
    expect(after.opacity, closeTo(1, 1e-9));
  });

  test('everything fades from 68.6 to 70, slow at first (power1.in)', () {
    expect(ending.fade(68.6), closeTo(1, 1e-9));
    expect(ending.fade(69.3), closeTo(0.75, 1e-9));
    expect(ending.fade(70), closeTo(0, 1e-9));
    expect(ending.visibleAt(70), isFalse);
  });

  test('a longer film ends later: it follows e, not 60.95', () {
    final longer = GoldenVowsEnding(
      GoldenVowsAmbient(GoldenVowsTimeline(heroes: 6)),
    );
    expect(longer.start, closeTo(e + 2 * 4.25, 1e-9));
    expect(longer.balloonY(longer.start + 2.6), closeTo(560, 1e-9));
  });

  test('the line reads the names and the date in the UI language', () {
    final en = GoldenVowsTexts(
      GoldenVowsFixtures.wedding,
      lookupAppLocalizations(const Locale('en')),
    );
    expect(en.ending.line.plainText, 'ANNA & MARCO · 14 JUNE 2026');
    expect(en.ending.wordmark(8).plainText, 'Storyni');
    en.dispose();
    final ru = GoldenVowsTexts(
      GoldenVowsFixtures.weddingRu,
      lookupAppLocalizations(const Locale('ru')),
    );
    expect(ru.ending.line.plainText, 'АННА И МАРКО · 14 ИЮНЯ 2026');
    ru.dispose();
  });

  testWidgets('the same instant renders the same pixels (export-ready)', (
    tester,
  ) async {
    final texts = GoldenVowsTexts(
      GoldenVowsFixtures.wedding,
      lookupAppLocalizations(const Locale('en')),
    );
    Future<Uint8List> render(double t) async {
      final recorder = ui.PictureRecorder();
      GoldenVowsEndingPainter(
        ending: ending,
        texts: texts.ending,
        time: ValueNotifier(t),
      ).paint(Canvas(recorder), const Size(1080, 1920));
      final picture = recorder.endRecording();
      final image = await picture.toImage(1080, 1920);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    await tester.runAsync(() async {
      for (final t in const [62.0, 63.4, 66.6, 69.3]) {
        expect(listEquals(await render(t), await render(t)), isTrue);
      }
    });
    texts.dispose();
  });
}
