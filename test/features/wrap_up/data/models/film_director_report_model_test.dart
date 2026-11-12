import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/film_director_report_model.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_scene.dart';

void main() {
  group('FilmDirectorReportModel.fromJson', () {
    test('parses a planned run: plan, photo counts and usage', () {
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
        'plan': {
          'plan_version': 2,
          'occasion': 'party',
          'recipe': 'rave',
          'music': {'energy': 'high'},
          'language': 'en',
          'reasoning': 'Club photos, crowds.',
          'footnote': {'line': 'Ears still ringing.'},
          'closing_line': 'You danced it off.',
          'chapters': [
            {
              'bridge_line': 'Doors at ten.',
              'scenes': [
                {
                  'type': 'burst',
                  'photo_ids': ['a', 'b', 'c'],
                  'caption_note_id': 'n1',
                  'text': null,
                  'duration_s': 2.5,
                  'emphasis': 'hero',
                },
                {
                  'type': 'text_card',
                  'photo_ids': <String>[],
                  'text': 'Then it got loud.',
                  'duration_s': 2,
                  'emphasis': 'normal',
                },
              ],
            },
          ],
        },
      })!;

      expect(report.isPlanned, isTrue);
      expect(report.recipe, 'rave');
      expect(report.occasion, 'party');
      expect(report.musicEnergy, 'high');
      expect(report.reasoning, 'Club photos, crowds.');
      expect(report.footnoteLine, 'Ears still ringing.');
      expect(report.closingLine, 'You danced it off.');
      expect(report.cachedPhotos, 10);
      expect(report.inputTokens, 5800);
      expect(report.estimatedUsd, 0.0184);
      expect(report.ranAt, DateTime.utc(2026, 11, 8, 12));
      expect(report.durationSeconds, 4.5);
      expect(
        report.chapters.single.scenes.first,
        const FilmPlanScene(
          type: 'burst',
          photoIds: ['a', 'b', 'c'],
          captionNoteId: 'n1',
          durationSeconds: 2.5,
          isHero: true,
        ),
      );
      expect(report.chapters.single.scenes.last.text, 'Then it got loud.');
    });

    test('parses a fallback run with its problems and no plan', () {
      final report = FilmDirectorReportModel.fromJson({
        'status': 'fallback',
        'plan': null,
        'problems': ['closing_line: banned phrase "epic"'],
        'attempts': 2,
      })!;

      expect(report.isPlanned, isFalse);
      expect(report.chapters, isEmpty);
      expect(report.problems, ['closing_line: banned phrase "epic"']);
      expect(report.attempts, 2);
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
