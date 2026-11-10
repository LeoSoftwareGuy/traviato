import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/film_plan_model.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_model.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_chapter.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_scene.dart';

/// A keepsake plan shaped like the director's (supabase/functions/
/// generate_wrap_up/director_fixtures.ts `keepsakePlan`).
Map<String, dynamic> _plan() => {
  'plan_version': 2,
  'occasion': 'city',
  'recipe': 'keepsake',
  'music': {'energy': 'calm'},
  'language': 'en',
  'chapters': [
    {
      'bridge_line': 'You came for the canals.',
      'scenes': [
        {
          'type': 'card_flip',
          'photo_ids': ['p0'],
          'caption_note_id': 'n1',
          'emphasis': 'hero',
          'duration_s': 5,
        },
        {
          'type': 'collage_3',
          'photo_ids': ['p1', 'p2', 'p3'],
          'duration_s': 4.5,
        },
      ],
    },
    {
      'bridge_line': 'Then the bikes won.',
      'scenes': [
        {
          'type': 'text_card',
          'photo_ids': <String>[],
          'text': 'Rain, mostly.',
          'duration_s': 3,
        },
      ],
    },
  ],
  'footnote': {'line': 'Three days, one wet umbrella.'},
  'closing_line': 'You left with dry socks, barely.',
  'reasoning': 'A quiet city trip, so keepsake.',
};

Map<String, dynamic> _content([Map<String, dynamic>? plan]) => {
  'plan_version': 2,
  'plan': plan ?? _plan(),
};

/// The plan's first scene, with [change] applied to it.
Map<String, dynamic> _withFirstScene(
  void Function(Map<String, dynamic>) change,
) {
  final plan = _plan();
  final chapters = plan['chapters'] as List;
  final scenes = (chapters.first as Map)['scenes'] as List;
  change(scenes.first as Map<String, dynamic>);
  return _content(plan);
}

void main() {
  group('parseFilmPlan', () {
    test('reads a whole plan', () {
      expect(
        parseFilmPlan(_content()),
        const FilmPlan(
          occasion: 'city',
          recipe: 'keepsake',
          chapters: [
            FilmPlanChapter(
              bridgeLine: 'You came for the canals.',
              scenes: [
                FilmPlanScene(
                  type: 'card_flip',
                  photoIds: ['p0'],
                  captionNoteId: 'n1',
                  durationSeconds: 5,
                  isHero: true,
                ),
                FilmPlanScene(
                  type: 'collage_3',
                  photoIds: ['p1', 'p2', 'p3'],
                  durationSeconds: 4.5,
                ),
              ],
            ),
            FilmPlanChapter(
              bridgeLine: 'Then the bikes won.',
              scenes: [
                FilmPlanScene(
                  type: 'text_card',
                  text: 'Rain, mostly.',
                  durationSeconds: 3,
                ),
              ],
            ),
          ],
          footnoteLine: 'Three days, one wet umbrella.',
          closingLine: 'You left with dry socks, barely.',
        ),
      );
      expect(parseFilmPlan(_content())!.durationSeconds, 12.5);
    });

    test('keeps scene types it has no player for', () {
      final plan = parseFilmPlan(_withFirstScene((s) => s['type'] = 'burst'));
      expect(plan!.chapters.first.scenes.first.type, 'burst');
    });

    test('a scene without photo_ids has none', () {
      final plan = parseFilmPlan(_withFirstScene((s) => s.remove('photo_ids')));
      expect(plan!.chapters.first.scenes.first.photoIds, isEmpty);
    });

    final invalid = <String, Map<String, dynamic>>{
      'no plan': const {},
      'no content plan_version': {'plan': _plan()},
      'content plan_version 1': {'plan_version': 1, 'plan': _plan()},
      'plan not a map': {'plan_version': 2, 'plan': 'plan'},
      'plan without plan_version': _content(_plan()..remove('plan_version')),
      'no chapters': _content(_plan()..remove('chapters')),
      'empty chapters': _content(_plan()..['chapters'] = <dynamic>[]),
      'chapters not a list': _content(_plan()..['chapters'] = {'a': 1}),
      'a chapter not a map': _content(
        _plan()..['chapters'] = [...(_plan()['chapters'] as List), 'x'],
      ),
      'a chapter without a bridge line': _content(
        _plan()
          ..['chapters'] = [
            {
              'scenes': [
                {'type': 'card_flip', 'duration_s': 4},
              ],
            },
          ],
      ),
      'a chapter without scenes': _content(
        _plan()
          ..['chapters'] = [
            {'bridge_line': 'x', 'scenes': <dynamic>[]},
          ],
      ),
      'a scene without a type': _withFirstScene((s) => s.remove('type')),
      'a scene with an empty type': _withFirstScene((s) => s['type'] = ''),
      'a scene without a duration': _withFirstScene(
        (s) => s.remove('duration_s'),
      ),
      'a scene of 0 seconds': _withFirstScene((s) => s['duration_s'] = 0),
      'a scene of negative seconds': _withFirstScene(
        (s) => s['duration_s'] = -2,
      ),
      'a scene of infinite seconds': _withFirstScene(
        (s) => s['duration_s'] = double.infinity,
      ),
      'a duration as text': _withFirstScene((s) => s['duration_s'] = '5'),
      'a photo id that is not text': _withFirstScene(
        (s) => s['photo_ids'] = ['p0', 7],
      ),
      'an empty photo id': _withFirstScene((s) => s['photo_ids'] = ['']),
      'photo_ids not a list': _withFirstScene((s) => s['photo_ids'] = 'p0'),
      'a caption note id that is not text': _withFirstScene(
        (s) => s['caption_note_id'] = 3,
      ),
      'text that is not text': _withFirstScene((s) => s['text'] = ['a']),
    };
    for (final MapEntry(key: name, value: content) in invalid.entries) {
      test('$name gives no plan', () {
        expect(parseFilmPlan(content), isNull);
      });
    }
  });

  group('WrapUpModel.fromRow plan (#344)', () {
    test('exposes a whole plan', () {
      final wrapUp = WrapUpModel.fromRow({'content': _content()});
      expect(wrapUp.plan, parseFilmPlan(_content()));
    });

    test('a broken plan gives null and the rest still parses', () {
      final wrapUp = WrapUpModel.fromRow({
        'content': {
          'invitation': {'line1': 'Five days.', 'line2': 'One long road.'},
          'plan_version': 2,
          'plan': {'plan_version': 2, 'chapters': 'nope'},
        },
      });
      expect(wrapUp.plan, isNull);
      expect(wrapUp.invitation.line1, 'Five days.');
    });

    test('a wrap-up without a plan has none', () {
      expect(WrapUpModel.fromRow(const {'content': {}}).plan, isNull);
    });
  });
}
