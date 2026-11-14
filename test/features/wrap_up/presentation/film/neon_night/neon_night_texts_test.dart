import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_scene_painter.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_text_fx.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_tokens.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_type.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../../../../helpers/font_codepoints.dart';
import 'neon_test_fonts.dart';

void main() {
  final en = lookupAppLocalizations(const ui.Locale('en'));
  final ru = lookupAppLocalizations(const ui.Locale('ru'));

  setUpAll(loadNeonNightFonts);

  test("the spec's auto-fit: min(maxSize, maxWidth / (chars × k))", () {
    expect(NeonType.fit('NIGHT OUT', 960, 230, 0.47), closeTo(226.95, 0.01));
    expect(NeonType.fit('NIGHT', 960, 230, 0.47), 230);
    // The longest line decides.
    expect(
      NeonType.fit('SECRET\nROOM ROOM ROOM', 860, 170, 0.5),
      860 / (14 * 0.5),
    );
  });

  test('the date in the UI language, no counts', () {
    final date = DateTime(2026, 11, 14);
    expect(NnIgnitionTexts.formatDate(date, 'en'), 'SAT 14 NOV');
    expect(NnIgnitionTexts.formatDate(date, 'ru'), 'СБ 14 НОЯБ.');
  });

  group('plan', () {
    test('done rows count up: cyan, pink, violet; others stay grey', () {
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      final plan = texts.plan!;
      expect([for (final r in plan.rows) r.doneIndex], [0, 1, 2, null, null]);
      expect(
        [for (final r in plan.rows.take(3)) r.color],
        [
          NeonColors.cyan,
          NeonColors.pink,
          NeonColors.violet,
        ],
      );
      expect(plan.more, isNull);
      texts.dispose();
    });

    test('a longer plan shows 5 rows and "+N MORE"', () {
      final texts = NeonNightTexts(NeonNightFixtures.longPlan, en);
      final plan = texts.plan!;
      expect(plan.rows, hasLength(5));
      // 14:00 ✓, 15:30 ✓, 18:00, 20:00 ✓, 22:00 ✓.
      expect([for (final r in plan.rows) r.doneIndex], [0, 1, null, 2, 3]);
      expect(plan.rows[4].color, NeonColors.cyan);
      expect(
        (plan.more!.text! as TextSpan).text,
        '+3 MORE',
      );
      texts.dispose();
      final ruTexts = NeonNightTexts(NeonNightFixtures.longPlan, ru);
      expect((ruTexts.plan!.more!.text! as TextSpan).text, 'И ЕЩЁ 3');
      ruTexts.dispose();
    });

    test('no plan → no plan texts', () {
      final texts = NeonNightTexts(
        NeonNightStory(title: 'Rave', date: DateTime(2026)),
        en,
      );
      expect(texts.plan, isNull);
      texts.dispose();
    });

    test('items and titles stay inside their width, Cyrillic too', () {
      for (final (story, l10n) in [
        (NeonNightFixtures.reference, en),
        (NeonNightFixtures.referenceRu, ru),
      ]) {
        final texts = NeonNightTexts(story, l10n);
        expect(
          texts.ignition.title.size.width,
          lessThanOrEqualTo(NnIgnitionTexts.titleWidth + 1),
        );
        expect(texts.plan!.title.size.width, lessThanOrEqualTo(861));
        for (final row in texts.plan!.rows) {
          expect(
            row.item.size.width,
            lessThanOrEqualTo(NnPlanRowTexts.itemWidth + 1),
          );
        }
        texts.dispose();
      }
    });

    test('item baselines line up with the time', () {
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      final row = texts.plan!.rows[2];
      expect(row.itemDrop, greaterThan(0));
      expect(
        row.itemDrop + row.item.baseline,
        closeTo(row.time.baseline, 1e-6),
      );
      texts.dispose();
    });
  });

  test("the bundled fonts cover every word the film shows, EN and RU", () {
    final display = fontCodepoints(
      'assets/fonts/BigShouldersDisplay[wght].ttf',
    );
    final fallback = fontCodepoints(
      'assets/fonts/FiraSansExtraCondensed-Black.ttf',
    );
    final mono = fontCodepoints('assets/fonts/JetBrainsMono[wght].ttf');
    final titles = [
      for (final l10n in [en, ru]) l10n.neonNight_planTitle.toUpperCase(),
      for (final story in [
        NeonNightFixtures.reference,
        NeonNightFixtures.referenceRu,
      ]) ...[
        story.title.toUpperCase(),
        for (final row in story.plan) ...[row.time, row.item.toUpperCase()],
      ],
    ];
    expect(missingCodepoints(display.union(fallback), titles), isEmpty);
    // Big Shoulders has no Cyrillic: that's what the fallback is for.
    expect(missingCodepoints(display, [ru.neonNight_planTitle]), isNotEmpty);
    expect(
      missingCodepoints(mono, [
        for (final l10n in [en, ru]) l10n.neonNight_planMore(3).toUpperCase(),
        NnIgnitionTexts.formatDate(DateTime(2026, 11, 14), 'en'),
        NnIgnitionTexts.formatDate(DateTime(2026, 11, 14), 'ru'),
      ]),
      isEmpty,
    );
  });

  group('glitch-in (§3.5)', () {
    List<(double, double)> calls(double t, {bool reduced = false}) {
      final calls = <(double, double)>[];
      neonGlitchIn(
        Canvas(ui.PictureRecorder()),
        t: t,
        at: 1,
        seed: 11,
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
        reducedFlashing: reduced,
        paintAt: (dx, alpha) => calls.add((dx, alpha)),
      );
      return calls;
    }

    test('nothing before, base + 3 slices while tearing, still after', () {
      expect(calls(0.99), isEmpty);
      expect(calls(1.1), hasLength(4));
      expect(calls(1.1), calls(1.1));
      expect(calls(1.5), [(0.0, 1.0)]);
    });

    test('reduced flashing: a 0.3 s fade, no slices', () {
      final fading = calls(1.15, reduced: true);
      expect(fading, hasLength(1));
      expect(fading.single.$1, 0);
      expect(fading.single.$2, closeTo(0.5, 1e-9));
      expect(calls(1.4, reduced: true), [(0.0, 1.0)]);
    });
  });

  group('export-ready (#345 rules)', () {
    Future<Uint8List> render(double t, NeonNightTexts texts) async {
      final painter = NeonScenePainter(
        timeline: NeonNightTimeline.reference(),
        texts: texts,
        time: ValueNotifier(t),
      );
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(1080, 1920));
      final picture = recorder.endRecording();
      final image = await picture.toImage(540, 960);
      final bytes = await image.toByteData();
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }

    testWidgets('Ignition and Plan render the same at the same instant', (
      tester,
    ) async {
      final texts = NeonNightTexts(NeonNightFixtures.reference, en);
      await tester.runAsync(() async {
        // Mid-glitch, the reflection, mid-tick, a flare.
        for (final t in const [2.0, 2.2, 3.2, 4.1, 6.3, 8.0]) {
          expect(
            listEquals(await render(t, texts), await render(t, texts)),
            isTrue,
            reason: 't = $t',
          );
        }
      });
      texts.dispose();
    });
  });
}
