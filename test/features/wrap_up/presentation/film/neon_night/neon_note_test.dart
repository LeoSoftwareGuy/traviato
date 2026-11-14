import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_photo_images.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_scene_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_tokens.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_type.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';
import 'neon_test_photos.dart';

void main() {
  final en = lookupAppLocalizations(const ui.Locale('en'));
  final ru = lookupAppLocalizations(const ui.Locale('ru'));

  group('note lines (§5.7)', () {
    test("keeps the user's line breaks, in capitals", () {
      expect(
        neonNoteLines(
          'We lost each other\nFound each other\nBy the bass\nBest night ever',
        ),
        [
          'WE LOST EACH OTHER',
          'FOUND EACH OTHER',
          'BY THE BASS',
          'BEST NIGHT EVER',
        ],
      );
    });

    test('wraps each line greedily at 18 characters', () {
      expect(
        neonNoteLines('we danced until the lights came up at six'),
        ['WE DANCED UNTIL', 'THE LIGHTS CAME UP', 'AT SIX'],
      );
      // A word longer than a line keeps a line to itself.
      expect(
        neonNoteLines('a supercalifragilisticexpialidocious night'),
        ['A', 'SUPERCALIFRAGILISTICEXPIALIDOCIOUS', 'NIGHT'],
      );
    });

    test('blank lines and extra spaces are dropped', () {
      expect(neonNoteLines('  one  \n\n two '), ['ONE', 'TWO']);
    });

    test('more than 5 lines: cut at a whole word, ending in "…"', () {
      final lines = neonNoteLines(
        'one\ntwo\nthree\nfour\nfive six seven eight nine ten\neleven',
      );
      expect(lines, hasLength(5));
      expect(lines.last, endsWith('…'));
      expect(lines.last.length, lessThanOrEqualTo(18));
      expect(lines.last, 'FIVE SIX SEVEN…');
    });
  });

  group('the scene', () {
    test('no note → no Note scene, 12 beats shorter', () {
      final reference = NeonNightFixtures.reference;
      final without = NeonNightStory(
        title: reference.title,
        date: reference.date,
        chapters: reference.chapters,
        plan: reference.plan,
      );
      final full = NeonNightCanvas.timelineFor(reference);
      final short = NeonNightCanvas.timelineFor(without);
      expect(full.scenes.where((s) => s.spec is NnNoteSpec), hasLength(1));
      expect(short.scenes.where((s) => s.spec is NnNoteSpec), isEmpty);
      expect(full.totalBeats - short.totalBeats, 12);
      expect(full.total - short.total, closeTo(5.714, 0.001));
    });

    test("the note's photo decodes small: it is blurred", () {
      final story = NeonNightFixtures.reference;
      final (:thumbs, large: _) = NeonPhotoImages.idsFor(
        story,
        NeonNightCanvas.timelineFor(story),
      );
      expect(thumbs, contains(story.note!.photo!.id));
    });
  });

  group('texts', () {
    setUpAll(loadNeonNightFonts);

    test('tag, lines in cyan/pink/cyan/green, signature', () {
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      final note = texts.note!;
      expect(note.tag.text, 'NOTE 04 · 00:31');
      expect(note.lines, hasLength(4));
      expect(NnNoteTexts.colors.take(4), [
        NeonColors.cyan,
        NeonColors.pink,
        NeonColors.cyan,
        NeonColors.green,
      ]);
      // fit(900, 210, 0.43) on the 18-character line: ≈ 116 px.
      expect(note.fontSize, closeTo(900 / (18 * 0.43), 0.01));
      for (final line in note.lines) {
        expect(line.size.width, lessThanOrEqualTo(NnNoteTexts.lineWidth + 1));
      }
      expect((note.signature!.text! as TextSpan).text, '— Leo');
      expect(NeonScenePainter.lineTop(note, 0), 720);
      expect(
        NeonScenePainter.lineTop(note, 2),
        closeTo(720 + 2 * 1.06 * note.fontSize, 1e-9),
      );
      texts.dispose();
    });

    test('in Russian; without a time or a name', () {
      final texts = NeonNightTexts(NeonNightFixtures.referenceRu, ru);
      expect(texts.note!.tag.text, 'ЗАМЕТКА 04 · 00:31');
      expect(texts.note!.lines, hasLength(3));
      texts.dispose();
      final few = NeonNightTexts(NeonNightFixtures.few, en);
      expect(few.note!.tag.text, 'NOTE 01');
      expect(few.note!.signature, isNull);
      few.dispose();
    });
  });

  testWidgets('the Note renders the same at the same instant', (tester) async {
    await loadNeonNightFonts();
    final story = NeonNightFixtures.reference;
    final texts = NeonNightTexts(story, en);
    final timeline = NeonNightCanvas.timelineFor(story);
    Future<Uint8List> render(double t) async {
      final painter = NeonScenePainter(
        timeline: timeline,
        story: story,
        texts: texts,
        photos: const NoPhotos(),
        time: ValueNotifier(t),
      );
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(1080, 1920));
      final picture = recorder.endRecording();
      final image = await picture.toImage(270, 480);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    await tester.runAsync(() async {
      // Fading in, a flicker dip, mid-beat glow, the signature, the exit.
      for (final t in const [45.8, 46.3, 47.0, 49.05, 50.6, 51.3]) {
        expect(
          listEquals(await render(t), await render(t)),
          isTrue,
          reason: 't = $t',
        );
      }
    });
    texts.dispose();
  });
}
