import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_unlock.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_scenes.dart';

import '../../fakes/fake_wrap_up_repository.dart';

List<WrapUpPhotoRef> _refs(int n, String prefix) => [
  for (var i = 0; i < n; i++) WrapUpPhotoRef(photoId: '$prefix$i'),
];

WrapUpFilmScenes _scenesFor({
  required WrapUpFilmCut? cut,
  required int moments,
  int flurry1 = 0,
  int flurry2 = 0,
  bool unlock = true,
}) {
  return WrapUpFilmScenes.forWrapUp(
    buildWrapUpEntity(
      cut: cut,
      moments: [
        for (var i = 0; i < moments; i++) WrapUpMoment(photoId: 'm$i'),
      ],
      flurryLeftovers: WrapUpFlurryLeftovers(
        flurry1: _refs(flurry1, 'a'),
        flurry2: _refs(flurry2, 'b'),
      ),
      unlock: unlock
          ? const WrapUpUnlock(code: 'c', name: 'N', reason: 'R')
          : null,
    ),
  );
}

void main() {
  group('WrapUpFilmScenes', () {
    test('with Flurry2 and Unlock both present, scenes run back-to-back '
        'with no gaps or overlaps', () {
      final scenes = WrapUpFilmScenes(hasFlurry2: true, hasUnlock: true);

      // docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md's scene table, in absolute-start order.
      final entries = <(String, double, double)>[
        ('Dust', scenes.dustStart, WrapUpFilmScenes.dustDur),
        ('Invitation', scenes.invitationStart, WrapUpFilmScenes.invitationDur),
        ('Bridge1', scenes.bridge1Start, WrapUpFilmScenes.bridge1Dur),
        (
          'M1',
          scenes.momentStarts[0],
          WrapUpFilmScenes.momentDurations[0],
        ),
        (
          'M2',
          scenes.momentStarts[1],
          WrapUpFilmScenes.momentDurations[1],
        ),
        (
          'M3',
          scenes.momentStarts[2],
          WrapUpFilmScenes.momentDurations[2],
        ),
        ('Flurry1', scenes.flurry1Start, WrapUpFilmScenes.flurry1Dur),
        ('Bridge2', scenes.bridge2Start, WrapUpFilmScenes.bridge2Dur),
        (
          'M4',
          scenes.momentStarts[3],
          WrapUpFilmScenes.momentDurations[3],
        ),
        (
          'M5',
          scenes.momentStarts[4],
          WrapUpFilmScenes.momentDurations[4],
        ),
        (
          'M6',
          scenes.momentStarts[5],
          WrapUpFilmScenes.momentDurations[5],
        ),
        ('Flurry2', scenes.flurry2Start, WrapUpFilmScenes.flurry2Dur),
        ('Bridge3', scenes.bridge3Start, WrapUpFilmScenes.bridge3Dur),
        (
          'M7',
          scenes.momentStarts[6],
          WrapUpFilmScenes.momentDurations[6],
        ),
        (
          'M8',
          scenes.momentStarts[7],
          WrapUpFilmScenes.momentDurations[7],
        ),
        ('Footnote', scenes.footnoteStart, WrapUpFilmScenes.footnoteDur),
        ('Unlock', scenes.unlockStart, WrapUpFilmScenes.unlockDur),
        ('Keepsake', scenes.keepsakeStart, WrapUpFilmScenes.keepsakeDur),
      ];

      for (var i = 1; i < entries.length; i++) {
        final (prevName, prevStart, prevDur) = entries[i - 1];
        final (name, start, _) = entries[i];
        expect(
          start,
          closeTo(prevStart + prevDur, 0.001),
          reason: '$name should start exactly when $prevName ends',
        );
      }

      final (lastName, lastStart, lastDur) = entries.last;
      expect(
        lastStart + lastDur,
        closeTo(scenes.total, 0.001),
        reason: '$lastName should end exactly at the film\'s total length',
      );
    });

    test('exposes exactly 8 moment start times', () {
      final scenes = WrapUpFilmScenes(hasFlurry2: true, hasUnlock: true);
      expect(scenes.momentStarts, hasLength(8));
      expect(WrapUpFilmScenes.momentDurations, hasLength(8));
    });

    test('cutting Flurry2 shortens the total by exactly flurry2Dur and '
        'Bridge3 starts where Flurry2 would have', () {
      final withFlurry2 = WrapUpFilmScenes(hasFlurry2: true, hasUnlock: true);
      final withoutFlurry2 = WrapUpFilmScenes(
        hasFlurry2: false,
        hasUnlock: true,
      );

      expect(withoutFlurry2.flurry2Start, withFlurry2.flurry2Start);
      expect(withoutFlurry2.bridge3Start, withFlurry2.flurry2Start);
      expect(
        withoutFlurry2.total,
        closeTo(withFlurry2.total - WrapUpFilmScenes.flurry2Dur, 0.001),
      );
      // Nothing before the cut moves.
      expect(withoutFlurry2.bridge2Start, withFlurry2.bridge2Start);
    });

    test('cutting Unlock shortens the total by exactly unlockDur and '
        'Keepsake starts where Unlock would have', () {
      final withUnlock = WrapUpFilmScenes(hasFlurry2: true, hasUnlock: true);
      final withoutUnlock = WrapUpFilmScenes(
        hasFlurry2: true,
        hasUnlock: false,
      );

      expect(withoutUnlock.unlockStart, withUnlock.unlockStart);
      expect(withoutUnlock.keepsakeStart, withUnlock.unlockStart);
      expect(
        withoutUnlock.total,
        closeTo(withUnlock.total - WrapUpFilmScenes.unlockDur, 0.001),
      );
      // Nothing before the cut moves.
      expect(withoutUnlock.footnoteStart, withUnlock.footnoteStart);
    });

    test('cutting both Flurry2 and Unlock compounds both savings', () {
      final full = WrapUpFilmScenes(hasFlurry2: true, hasUnlock: true);
      final neither = WrapUpFilmScenes(hasFlurry2: false, hasUnlock: false);

      expect(
        neither.total,
        closeTo(
          full.total - WrapUpFilmScenes.flurry2Dur - WrapUpFilmScenes.unlockDur,
          0.001,
        ),
      );
    });
  });

  group('WrapUpFilmScenes.forWrapUp (#151 cuts)', () {
    test('highlight with 5 moments: no Flurries, no Bridge3, 63.4s', () {
      final scenes = _scenesFor(cut: WrapUpFilmCut.highlight, moments: 5);

      expect(scenes.momentStarts, hasLength(5));
      expect(scenes.hasFlurry1, isFalse);
      expect(scenes.hasFlurry2, isFalse);
      expect(scenes.hasBridge2, isTrue);
      expect(scenes.hasBridge3, isFalse);
      expect(scenes.total, closeTo(63.4, 0.001));
      // M4 follows Bridge2 directly, and Footnote follows M5 directly.
      expect(
        scenes.momentStarts[3],
        closeTo(scenes.bridge2Start + WrapUpFilmScenes.bridge2Dur, 0.001),
      );
      expect(
        scenes.footnoteStart,
        closeTo(
          scenes.momentStarts[4] + WrapUpFilmScenes.momentDurations[4],
          0.001,
        ),
      );
    });

    test('highlight with 8 moments keeps Bridge3: 86.6s', () {
      final scenes = _scenesFor(cut: WrapUpFilmCut.highlight, moments: 8);
      expect(scenes.hasBridge3, isTrue);
      expect(scenes.total, closeTo(86.6, 0.001));
    });

    test('compact with its one Flurry: 92.9s, Flurry1 slot only', () {
      final scenes = _scenesFor(
        cut: WrapUpFilmCut.compact,
        moments: 8,
        flurry1: 7,
      );
      expect(scenes.hasFlurry1, isTrue);
      expect(scenes.hasFlurry2, isFalse);
      expect(scenes.total, closeTo(92.9, 0.001));
    });

    test('full with both Flurries is the whole 99.9s film', () {
      final scenes = _scenesFor(
        cut: WrapUpFilmCut.full,
        moments: 8,
        flurry1: 11,
        flurry2: 6,
      );
      expect(scenes.total, closeTo(99.9, 0.001));
    });

    test('no achievement drops Unlock from any cut', () {
      final scenes = _scenesFor(
        cut: WrapUpFilmCut.highlight,
        moments: 5,
        unlock: false,
      );
      expect(scenes.total, closeTo(63.4 - WrapUpFilmScenes.unlockDur, 0.001));
    });

    test('a pre-#151 wrap-up keeps the original schedule', () {
      final legacy = _scenesFor(cut: null, moments: 3);
      final original = WrapUpFilmScenes(hasFlurry2: false, hasUnlock: true);

      expect(legacy.momentStarts, original.momentStarts);
      expect(legacy.momentStarts, hasLength(8));
      expect(legacy.hasFlurry1, isTrue);
      expect(legacy.total, original.total);
    });

    test('every cut keeps the chrome anchors in film order', () {
      for (final scenes in [
        _scenesFor(cut: WrapUpFilmCut.highlight, moments: 5),
        _scenesFor(cut: WrapUpFilmCut.compact, moments: 8, flurry1: 6),
        _scenesFor(cut: WrapUpFilmCut.full, moments: 8, flurry1: 6),
      ]) {
        expect(scenes.invitationStart, lessThan(scenes.bridge1Start));
        expect(scenes.bridge1Start, lessThan(scenes.footnoteStart));
        expect(scenes.footnoteStart, lessThan(scenes.keepsakeStart));
        expect(
          scenes.keepsakeStart + WrapUpFilmScenes.keepsakeDur,
          closeTo(scenes.total, 0.001),
        );
      }
    });
  });
}
