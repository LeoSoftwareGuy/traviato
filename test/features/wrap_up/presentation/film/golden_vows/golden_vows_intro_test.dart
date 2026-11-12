import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_intro_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  setUpAll(() async {
    for (final (family, asset) in const [
      ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
      ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
      ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  group('invitation motion (spec §5.1)', () {
    test('the balloon rises, holds, and flies off', () {
      expect(GvInvitationMotion.balloonY(0), 1980);
      expect(GvInvitationMotion.balloonY(3.6), 330);
      expect(GvInvitationMotion.balloonY(4.6), 330);
      expect(GvInvitationMotion.balloonY(6.2), -420);
    });

    test('it rocks −6° ↔ 4° on 1.8 s legs, three of them', () {
      expect(GvInvitationMotion.balloonRock(0), -6);
      expect(GvInvitationMotion.balloonRock(1.8), closeTo(4, 1e-9));
      expect(GvInvitationMotion.balloonRock(3.6), closeTo(-6, 1e-9));
      expect(GvInvitationMotion.balloonRock(5.4), closeTo(4, 1e-9));
      expect(GvInvitationMotion.balloonRock(6.0), closeTo(4, 1e-9));
    });

    test('the lines leave from 5.0 s, 0.06 s apart, slow at first', () {
      expect(GvInvitationMotion.exit(5.0, 0), 0);
      expect(GvInvitationMotion.exit(5.4, 0), lessThan(0.1));
      expect(GvInvitationMotion.exit(5.9, 0), closeTo(1, 1e-9));
      expect(GvInvitationMotion.exit(5.9, 1), lessThan(1));
    });
  });

  group('packing card motion (spec §5.2, from 5.4 s)', () {
    test('rises to 360, tilts −2° then 1°, flies off at −10°', () {
      expect(GvCardMotion.top(0), 2000);
      expect(GvCardMotion.top(1.4), 360);
      expect(GvCardMotion.top(GvCardMotion.gone), -1500);
      expect(GvCardMotion.rotation(0), 6);
      expect(GvCardMotion.rotation(1.4), closeTo(-2, 1e-9));
      expect(GvCardMotion.rotation(5.9), closeTo(1, 1e-9));
      expect(GvCardMotion.rotation(GvCardMotion.gone), closeTo(-10, 1e-9));
    });

    test('items slide in from 6.3 s and tick from 7.4 s', () {
      expect(GvCardMotion.itemAt(0) + 5.4, closeTo(6.3, 1e-9));
      expect(GvCardMotion.itemAt(4) + 5.4, closeTo(6.86, 1e-9));
      expect(GvCardMotion.tickAt(0) + 5.4, closeTo(7.4, 1e-9));
      expect(GvCardMotion.tickAt(4) + 5.4, closeTo(10.6, 1e-9));
      expect(GvCardMotion.height(5), 1090);
    });

    test('starts at 5.4 s, or not at all with nothing packed', () {
      expect(GoldenVowsTimeline.reference().packingCardStart, 5.4);
      expect(GoldenVowsTimeline(hasPackingCard: false).packingCardStart, null);
    });
  });

  group('texts', () {
    test('the date reads the same in every language', () {
      final texts = GoldenVowsTexts(GoldenVowsFixtures.wedding, en);
      expect(texts.invitation.date.plainText, '14 · 06 · 2026');
      texts.dispose();
    });

    test('the card counts what was packed, uppercase', () {
      final texts = GoldenVowsTexts(GoldenVowsFixtures.wedding, en);
      expect(texts.packing!.subhead.plainText, 'WHAT WE PACKED · 5 OF 5');
      texts.dispose();
      final more = GoldenVowsTexts(
        GoldenVowsStory(
          names: 'A & B',
          date: DateTime(2026),
          packed: List.generate(7, (i) => 'Item $i'),
          packedTotal: 12,
        ),
        ru,
      );
      expect(more.packing!.items, hasLength(5));
      expect(more.packing!.subhead.plainText, 'ЧТО МЫ ВЗЯЛИ · 5 ИЗ 12');
      more.dispose();
    });

    test('missing lines are left out; nothing packed, no card', () {
      final texts = GoldenVowsTexts(
        GoldenVowsStory(names: 'Mia & Jonas', date: DateTime(2026, 9, 5)),
        en,
      );
      expect(texts.invitation.occasion, isNull);
      expect(texts.invitation.place, isNull);
      expect(texts.packing, isNull);
      texts.dispose();
    });

    test('long names, places and items shrink to fit', () {
      final texts = GoldenVowsTexts(
        GoldenVowsStory(
          names: 'Alexandra-Margaretha & Maximilian-Johannes',
          date: DateTime(2026),
          place: 'A very long place name that goes on, Somewhere, Far Away',
          packed: const [
            'An extremely long packing item that would never fit the card',
          ],
        ),
        en,
      );
      final inv = texts.invitation;
      expect(inv.names(2).width, lessThanOrEqualTo(900));
      expect(inv.place!.width, lessThanOrEqualTo(900));
      expect(
        texts.packing!.items.single.width,
        lessThanOrEqualTo(GvPackingTexts.itemMaxWidth),
      );
      texts.dispose();
    });
  });

  testWidgets('the same instant renders the same pixels (export-ready)', (
    tester,
  ) async {
    final texts = GoldenVowsTexts(GoldenVowsFixtures.wedding, en);
    final timeline = GoldenVowsTimeline.reference();
    Future<Uint8List> render(double t) async {
      final recorder = ui.PictureRecorder();
      GoldenVowsIntroPainter(
        timeline: timeline,
        texts: texts,
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
      for (final t in const [2.3, 4.4, 8.0, 11.0]) {
        expect(listEquals(await render(t), await render(t)), isTrue);
      }
    });
    texts.dispose();
  });
}
