import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_scenes.dart';

void main() {
  group('WrapUpFilmScenes', () {
    test('scenes run back-to-back with no gaps or overlaps', () {
      // docs/design/wrap-film-spec.md's scene table, in absolute-start order.
      final scenes = <(String, double, double)>[
        ('Dust', WrapUpFilmScenes.dustStart, WrapUpFilmScenes.dustDur),
        (
          'Invitation',
          WrapUpFilmScenes.invitationStart,
          WrapUpFilmScenes.invitationDur,
        ),
        ('Bridge1', WrapUpFilmScenes.bridge1Start, WrapUpFilmScenes.bridge1Dur),
        (
          'M1',
          WrapUpFilmScenes.momentStarts[0],
          WrapUpFilmScenes.momentDurations[0],
        ),
        (
          'M2',
          WrapUpFilmScenes.momentStarts[1],
          WrapUpFilmScenes.momentDurations[1],
        ),
        (
          'M3',
          WrapUpFilmScenes.momentStarts[2],
          WrapUpFilmScenes.momentDurations[2],
        ),
        (
          'Flurry1',
          WrapUpFilmScenes.flurry1Start,
          WrapUpFilmScenes.flurry1Dur,
        ),
        ('Bridge2', WrapUpFilmScenes.bridge2Start, WrapUpFilmScenes.bridge2Dur),
        (
          'M4',
          WrapUpFilmScenes.momentStarts[3],
          WrapUpFilmScenes.momentDurations[3],
        ),
        (
          'M5',
          WrapUpFilmScenes.momentStarts[4],
          WrapUpFilmScenes.momentDurations[4],
        ),
        (
          'M6',
          WrapUpFilmScenes.momentStarts[5],
          WrapUpFilmScenes.momentDurations[5],
        ),
        (
          'Flurry2',
          WrapUpFilmScenes.flurry2Start,
          WrapUpFilmScenes.flurry2Dur,
        ),
        ('Bridge3', WrapUpFilmScenes.bridge3Start, WrapUpFilmScenes.bridge3Dur),
        (
          'M7',
          WrapUpFilmScenes.momentStarts[6],
          WrapUpFilmScenes.momentDurations[6],
        ),
        (
          'M8',
          WrapUpFilmScenes.momentStarts[7],
          WrapUpFilmScenes.momentDurations[7],
        ),
        (
          'Footnote',
          WrapUpFilmScenes.footnoteStart,
          WrapUpFilmScenes.footnoteDur,
        ),
        ('Unlock', WrapUpFilmScenes.unlockStart, WrapUpFilmScenes.unlockDur),
        (
          'Keepsake',
          WrapUpFilmScenes.keepsakeStart,
          WrapUpFilmScenes.keepsakeDur,
        ),
      ];

      for (var i = 1; i < scenes.length; i++) {
        final (prevName, prevStart, prevDur) = scenes[i - 1];
        final (name, start, _) = scenes[i];
        expect(
          start,
          closeTo(prevStart + prevDur, 0.001),
          reason: '$name should start exactly when $prevName ends',
        );
      }

      final (lastName, lastStart, lastDur) = scenes.last;
      expect(
        lastStart + lastDur,
        closeTo(WrapUpFilmScenes.total, 0.001),
        reason: '$lastName should end exactly at the film\'s total length',
      );
    });

    test('exposes exactly 8 moment start/duration pairs', () {
      expect(WrapUpFilmScenes.momentStarts, hasLength(8));
      expect(WrapUpFilmScenes.momentDurations, hasLength(8));
    });
  });
}
