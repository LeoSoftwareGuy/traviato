import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/film_director_report_model.dart';

void main() {
  group('FilmDirectorReportModel.fromJson', () {
    test('parses a planned run: photo counts and usage', () {
      final report = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'attempts': 1,
        'model': 'claude-sonnet-5',
        'ran_at': '2026-11-08T12:00:00Z',
        'problems': <String>[],
        'photos': {
          'plannable': 12,
          'analysed_now': 2,
          'cached': 10,
          'failed': 0,
        },
        'usage': {
          'input_tokens': 5800,
          'output_tokens': 680,
          'estimated_usd': 0.0184,
        },
      })!;

      // Planned: the director picked the words (#463), no plan needed.
      expect(report.isPlanned, isTrue);
      expect(report.cachedPhotos, 10);
      expect(report.inputTokens, 5800);
      expect(report.estimatedUsd, 0.0184);
      expect(report.ranAt, DateTime.utc(2026, 11, 8, 12));
    });

    test('parses a fallback run with its problems', () {
      final report = FilmDirectorReportModel.fromJson({
        'status': 'fallback',
        'plan': null,
        'problems': ['only 3 analysed photos'],
        'attempts': 2,
      })!;

      expect(report.isPlanned, isFalse);
      expect(report.problems, ['only 3 analysed photos']);
      expect(report.attempts, 2);
    });

    test('reads Sky Story: slots, trims, photos on pages, unlisted (#463)', () {
      final report = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
        'sky': {'picks_version': 2, 'picks': <String, Object>{}},
        'sky_slots': [
          {
            'slot': 'p1.line1',
            'candidates': [
              {'id': 'n:n1:abc', 'text': 'Tram 28 to the castle.', 'score': 80},
            ],
            'pick': {
              'ids': ['p1.line1/n:n1:abc'],
              'free_title': null,
            },
            'chosen': [
              {'id': 'n:n1:abc', 'text': 'Tram 28 to the castle.'},
            ],
            'source': 'director',
            'reason': "director's pick",
          },
        ],
        'sky_trims': ['p5: a second line left out'],
        'sky_shown': {'pages': 20, 'photos': 34},
        'sky_unlisted': [
          {'note_id': 'n4', 'text': 'Rain all day.', 'reason': 'no page'},
        ],
        'sky_problems': <String>[],
      })!;
      expect(report.skySlots.single.pickedIds, ['n:n1:abc']);
      expect(report.skySlots.single.source, 'director');
      expect(report.skyTrims, ['p5: a second line left out']);
      expect(report.skyShownPages, 20);
      expect(report.skyShownPhotos, 34);
      expect(report.skyUnlisted, ['Rain all day. — no page']);
      // A run from before #463: none of it.
      final old = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
      })!;
      expect(old.skySlots, isEmpty);
      expect(old.skyShownPhotos, isNull);
    });

    test('reads the Golden Vows occasion and problems (#346)', () {
      final chosen = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
        'golden_vows': {'occasion': 'anniversary'},
        'golden_vows_problems': <String>[],
      })!;
      expect(chosen.goldenVowsOccasion, 'anniversary');
      expect(chosen.goldenVowsProblems, isEmpty);
      final invalid = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
        'golden_vows': null,
        'golden_vows_problems': ['golden_vows.heroes: 1', 7],
      })!;
      expect(invalid.goldenVowsOccasion, isNull);
      expect(invalid.goldenVowsProblems, ['golden_vows.heroes: 1']);
    });

    test('reads whether there is a Neon Night section and its problems '
        '(#363)', () {
      final chosen = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
        'neon_night': {'chapters': <Object>[]},
        'neon_night_problems': <String>[],
      })!;
      expect(chosen.hasNeonNight, isTrue);
      expect(chosen.neonNightProblems, isEmpty);
      final invalid = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
        'neon_night': null,
        'neon_night_problems': ['neon_night.chapters: 0', 7],
      })!;
      expect(invalid.hasNeonNight, isFalse);
      expect(invalid.neonNightProblems, ['neon_night.chapters: 0']);
    });

    test('reads every Neon Night slot: candidates, pick, source (#454)', () {
      final report = FilmDirectorReportModel.fromJson({
        'status': 'planned',
        'problems': <String>[],
        'neon_night': {'picks_version': 2, 'picks': <String, Object>{}},
        'neon_slots': [
          {
            'slot': 'ch5.title',
            'candidates': [
              {'id': 'n:a:1', 'text': 'В Брюсель', 'score': 25},
              {'id': 'bad'},
              'junk',
            ],
            'pick': {
              'ids': ['ch5.title/n:a:1', 'n:b:2'],
              'free_title': 'Брюссель',
            },
            'chosen': [
              {'id': 'free', 'text': 'Брюссель'},
            ],
            'source': 'director',
            'reason': "director's pick",
          },
          {'candidates': <Object>[]},
          {'slot': 'headline', 'pick': null},
        ],
      })!;
      expect(report.hasNeonNight, isTrue);
      expect(report.neonSlots, hasLength(2));
      final title = report.neonSlots.first;
      expect(title.slot, 'ch5.title');
      expect(title.candidates.first.text, 'В Брюсель');
      expect(title.candidates.first.score, 25);
      expect(title.candidates[1].text, '');
      expect(title.pickedIds, ['n:a:1', 'n:b:2']);
      expect(title.freeText, 'Брюссель');
      expect(title.chosenIds, ['free']);
      expect(title.chosen, ['Брюссель']);
      expect(title.source, 'director');
      final headline = report.neonSlots[1];
      expect(headline.pickedIds, isEmpty);
      expect(headline.source, 'none');
      // A run from before #454 has no slots.
      expect(
        FilmDirectorReportModel.fromJson({
          'status': 'planned',
          'problems': <String>[],
        })!.neonSlots,
        isEmpty,
      );
    });

    test(
      'reads Golden Vows: slots, trims, photos shown, why a wedding (#458)',
      () {
        final report = FilmDirectorReportModel.fromJson({
          'status': 'fallback',
          'problems': <String>[],
          'golden_vows': {'picks_version': 2, 'picks': <String, Object>{}},
          'gv_slots': [
            {
              'slot': 'main1.note',
              'candidates': [
                {'id': 'n:n1:abc', 'text': 'Утро в Париже', 'score': 103},
              ],
              'pick': {
                'ids': ['main1.note/n:n1:abc'],
                'free_title': null,
              },
              'chosen': [
                {'id': 'n:n1:abc', 'text': 'Утро в Париже'},
              ],
              'source': 'director',
              'reason': "director's pick",
            },
          ],
          'gv_trims': ['main2.note: no note', 'no carousel'],
          'gv_shown': {'pages': 18, 'photos': 20},
          'gv_unlisted': [
            {'note_id': 'n4', 'text': 'Было хорошо.', 'reason': 'generic'},
            {'note_id': 'n5'},
          ],
          'gv_trigger': {'word': 'свадьба', 'source': 'note', 'id': 'n1'},
        })!;
        expect(report.gvSlots.single.pickedIds, ['n:n1:abc']);
        expect(report.gvSlots.single.source, 'director');
        expect(report.gvTrims, ['main2.note: no note', 'no carousel']);
        expect(report.gvShownPages, 18);
        expect(report.gvShownPhotos, 20);
        expect(report.gvUnlisted, ['Было хорошо. — generic']);
        expect(report.gvTrigger, '«свадьба» in note n1');
        // A run from before #458, or romance: none of it.
        final old = FilmDirectorReportModel.fromJson({
          'status': 'planned',
          'problems': <String>[],
          'gv_trigger': null,
        })!;
        expect(old.gvSlots, isEmpty);
        expect(old.gvShownPhotos, isNull);
        expect(old.gvTrigger, isNull);
      },
    );

    test("reads the vibes' film, its plan's source and repairs (#433)", () {
      final report = FilmDirectorReportModel.fromJson({
        'status': 'fallback',
        'plan': null,
        'problems': <String>[],
        'template': 'neon_night',
        'neon_night_source': 'director',
        'neon_night_repairs': ['repaired: neon_night.headline: 20 characters'],
        'golden_vows_source': 'code',
      })!;
      expect(report.template, 'neon_night');
      expect(report.filmSource, 'director');
      expect(report.filmRepairs, [
        'repaired: neon_night.headline: 20 characters',
      ]);

      final older = FilmDirectorReportModel.fromJson({
        'status': 'fallback',
        'problems': <String>[],
      })!;
      expect(older.template, isNull);
      expect(older.filmSource, isNull);
      expect(older.filmRepairs, isEmpty);
    });

    test('is null when the director never ran', () {
      expect(FilmDirectorReportModel.fromJson(null), isNull);
      expect(FilmDirectorReportModel.fromJson({'status': 'odd'}), isNull);
    });
  });

  test('filmPhotoAnalysisFromRow reads a photo_analysis row', () {
    final analysis = filmPhotoAnalysisFromRow({
      'photo_id': 'a',
      'summary': 'A canal at dusk',
      'setting': 'city',
      'people': '0',
      'energy': 'calm',
      'quality': 'sharp',
      'hero_score': 4,
      'dup_group': null,
    })!;
    expect(analysis.heroScore, 4);
    expect(analysis.summary, 'A canal at dusk');
    expect(filmPhotoAnalysisFromRow({'summary': 'no id'}), isNull);
  });
}
