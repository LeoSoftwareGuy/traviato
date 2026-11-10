import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_collage_layout.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_unlock.dart';
import 'package:traviato/features/wrap_up/presentation/film/timeline/film_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/timeline/film_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/timeline/template_timeline.dart';

import '../../../fakes/fake_wrap_up_repository.dart';
import '../legacy_film_scenes_oracle.dart';

List<WrapUpPhotoRef> _refs(int n, String prefix) => [
  for (var i = 0; i < n; i++) WrapUpPhotoRef(photoId: '$prefix$i'),
];

/// Moment i cycles through what changes its timing (#304): bare, a
/// caption, a badge, a collage.
WrapUpMoment _moment(int i) {
  final layout = i % 4 == 3
      ? WrapUpCollageLayout.values[i % WrapUpCollageLayout.values.length]
      : null;
  return WrapUpMoment(
    photoId: 'm$i',
    note: i % 4 == 1 ? 'note $i' : null,
    badge: i % 4 == 2 ? 'badge $i' : null,
    layout: layout,
    collageExtras: layout == null ? const [] : _refs(layout.tileCount - 1, 'x'),
  );
}

WrapUpEntity _wrapUp({
  WrapUpFilmCut? cut,
  int slots = 8,
  int moments = 8,
  int flurry1 = 0,
  int flurry2 = 0,
  int leftovers = 0,
  bool unlock = true,
}) => buildWrapUpEntity(
  cut: cut,
  momentSlots: slots,
  bridges: const ['b1', 'b2', 'b3'],
  moments: [for (var i = 0; i < moments; i++) _moment(i)],
  flurryLeftovers: WrapUpFlurryLeftovers(
    photos: _refs(leftovers, 'l'),
    flurry1: _refs(flurry1, 'a'),
    flurry2: _refs(flurry2, 'b'),
  ),
  unlock: unlock ? const WrapUpUnlock(code: 'c', name: 'N', reason: 'R') : null,
);

/// The pre-#344 schedule as `(scene, start, duration)`, in play order,
/// leaving out the scenes it cut.
List<(String, double, double)> _oracle(WrapUpEntity wrapUp) {
  final s = LegacyFilmScenes.forWrapUp(wrapUp);
  return [
    ('dust', s.dustStart, LegacyFilmScenes.dustDur),
    ('invitation', s.invitationStart, LegacyFilmScenes.invitationDur),
    ('bridge0', s.bridge1Start, LegacyFilmScenes.bridge1Dur),
    for (var i = 0; i < s.momentStarts.length; i++)
      ('moment', s.momentStarts[i], s.momentDurations[i]),
    if (s.hasFlurry1) ('flurry1', s.flurry1Start, LegacyFilmScenes.flurry1Dur),
    if (s.hasBridge2) ('bridge1', s.bridge2Start, LegacyFilmScenes.bridge2Dur),
    if (s.hasFlurry2) ('flurry2', s.flurry2Start, LegacyFilmScenes.flurry2Dur),
    if (s.hasBridge3) ('bridge2', s.bridge3Start, LegacyFilmScenes.bridge3Dur),
    ('footnote', s.footnoteStart, LegacyFilmScenes.footnoteDur),
    if (s.hasUnlock) ('unlock', s.unlockStart, LegacyFilmScenes.unlockDur),
    ('keepsake', s.keepsakeStart, LegacyFilmScenes.keepsakeDur),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
}

String _label(FilmSceneSpec spec) => switch (spec) {
  DustSceneSpec() => 'dust',
  InvitationSceneSpec() => 'invitation',
  BridgeSceneSpec(:final index) => 'bridge$index',
  CardFlipSceneSpec() || CollageSceneSpec() || HoldSceneSpec() => 'moment',
  FlurrySceneSpec(:final round) => 'flurry$round',
  FootnoteSceneSpec() => 'footnote',
  UnlockSceneSpec() => 'unlock',
  KeepsakeSceneSpec() => 'keepsake',
};

List<(String, double, double)> _schedule(FilmTimeline timeline) => [
  for (final scene in timeline.scenes)
    (_label(scene.spec), scene.start, scene.duration),
];

void main() {
  group('schedule equivalence with the pre-#344 player', () {
    // Every shape the template can take: legacy and each cut, 8 and 16
    // slots, any number of moments, either Flurry present or cut, with and
    // without an achievement, collages on or off.
    final cases = <String, WrapUpEntity>{};
    for (final cut in <WrapUpFilmCut?>[null, ...WrapUpFilmCut.values]) {
      for (final slots in [8, 16]) {
        for (final moments in [0, 1, 3, 4, 6, 7, 8, 12, 13, 16, 20]) {
          for (final (f1, f2) in [(0, 0), (5, 0), (0, 4), (12, 9)]) {
            for (final unlock in [true, false]) {
              cases['$cut slots=$slots moments=$moments '
                  'flurries=$f1/$f2 unlock=$unlock'] = _wrapUp(
                cut: cut,
                slots: slots,
                moments: moments,
                flurry1: f1,
                flurry2: f2,
                leftovers: f1 + f2 + 10,
                unlock: unlock,
              );
            }
          }
        }
      }
    }

    test('the same scenes start at the same instants for the same time', () {
      expect(cases, hasLength(4 * 2 * 11 * 4 * 2));
      for (final MapEntry(key: name, value: wrapUp) in cases.entries) {
        for (final collages in [true, false]) {
          final template = TemplateTimeline.forWrapUp(
            wrapUp,
            collages: collages,
          );
          expect(
            _schedule(template.timeline),
            _oracle(wrapUp),
            reason: '$name collages=$collages',
          );
          final oracle = LegacyFilmScenes.forWrapUp(wrapUp);
          expect(template.total, oracle.total, reason: name);
          expect(template.anchors.invitationStart, oracle.invitationStart);
          expect(template.anchors.bridge1Start, oracle.bridge1Start);
          expect(template.anchors.footnoteStart, oracle.footnoteStart);
          expect(template.anchors.keepsakeStart, oracle.keepsakeStart);
        }
      }
    });

    test('each moment slot shows that moment, as the old canvas did', () {
      for (final MapEntry(key: name, value: wrapUp) in cases.entries) {
        for (final collages in [true, false]) {
          final specs = [
            for (final scene in TemplateTimeline.forWrapUp(
              wrapUp,
              collages: collages,
            ).timeline.scenes)
              if (_label(scene.spec) == 'moment') scene.spec,
          ];
          for (final (i, spec) in specs.indexed) {
            final reason = '$name collages=$collages slot $i';
            if (i >= wrapUp.moments.length) {
              expect(spec, isA<HoldSceneSpec>(), reason: reason);
              continue;
            }
            final moment = wrapUp.moments[i];
            final isCollage =
                collages && wrapUp.cut != null && moment.layout != null;
            expect(
              spec,
              isCollage
                  ? CollageSceneSpec(moment: moment, layout: moment.layout!)
                  : CardFlipSceneSpec(pileIndex: i, moment: moment),
              reason: reason,
            );
          }
        }
      }
    });
  });

  group('TemplateTimeline', () {
    test('scenes run back to back from 0 to total', () {
      final timeline = TemplateTimeline.forWrapUp(
        _wrapUp(cut: WrapUpFilmCut.full, flurry1: 4, flurry2: 4),
      ).timeline;
      expect(timeline.scenes.first.start, 0);
      for (var i = 1; i < timeline.scenes.length; i++) {
        expect(timeline.scenes[i].start, timeline.scenes[i - 1].end);
      }
      expect(timeline.scenes.last.end, timeline.total);
    });

    test('a highlight with 5 bare moments runs 50.1s, no Flurry/Bridge3', () {
      final wrapUp = buildWrapUpEntity(
        cut: WrapUpFilmCut.highlight,
        bridges: const ['b1', 'b2', 'b3'],
        moments: [for (var i = 0; i < 5; i++) WrapUpMoment(photoId: 'm$i')],
        unlock: const WrapUpUnlock(code: 'c', name: 'N', reason: 'R'),
      );
      final template = TemplateTimeline.forWrapUp(wrapUp);
      expect(template.total, closeTo(50.1, 0.001));
      expect(template.timeline.first<FlurrySceneSpec>(), isNull);
      expect(
        [
          for (final s in template.timeline.scenes)
            if (s.spec case BridgeSceneSpec(:final index)) index,
        ],
        [0, 1],
      );
    });

    test('Flurry2 carries the leftovers label', () {
      final wrapUp = buildWrapUpEntity(
        cut: WrapUpFilmCut.full,
        flurryLeftovers: WrapUpFlurryLeftovers(
          flurry2: _refs(3, 'b'),
          totalRemainingLabel: '+ 9 more',
        ),
      );
      final flurry = TemplateTimeline.forWrapUp(
        wrapUp,
      ).timeline.first<FlurrySceneSpec>();
      expect(
        flurry?.spec,
        FlurrySceneSpec(
          round: 2,
          photos: _refs(3, 'b'),
          remainingLabel: '+ 9 more',
        ),
      );
    });

    test('a missing bridge line holds its time instead of a blank card', () {
      final wrapUp = buildWrapUpEntity(bridges: const ['only one']);
      final timeline = TemplateTimeline.forWrapUp(wrapUp).timeline;
      expect(
        [
          for (final s in timeline.scenes)
            if (s.spec is BridgeSceneSpec) s.spec,
        ],
        [const BridgeSceneSpec(index: 0, line: 'only one')],
      );
      expect(timeline.total, LegacyFilmScenes.forWrapUp(wrapUp).total);
    });

    test('a moment lasts by what it shows: flip, caption/badge, collage', () {
      double durationOf(WrapUpMoment m, {bool collage = false}) =>
          TemplateTimeline.momentDurationFor(m, isCollage: collage);

      expect(durationOf(const WrapUpMoment(photoId: 'p')), 2.5);
      expect(durationOf(const WrapUpMoment(photoId: 'p', note: 'n')), 3.5);
      expect(durationOf(const WrapUpMoment(photoId: 'p', badge: 'b')), 3.5);
      expect(
        durationOf(const WrapUpMoment(photoId: 'p', note: 'n'), collage: true),
        4.0,
      );
    });
  });
}
