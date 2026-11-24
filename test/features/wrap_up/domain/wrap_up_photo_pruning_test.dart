import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_collage_layout.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_photo_pruning.dart';

import '../fakes/fake_wrap_up_repository.dart';

WrapUpPhotoRef _ref(String id) => WrapUpPhotoRef(photoId: id);

void main() {
  final collage = WrapUpMoment(
    photoId: 'c0',
    note: 'Harbour at dusk',
    badge: 'Dare · Sunset · ✦2',
    layout: WrapUpCollageLayout.stack3,
    collageExtras: [_ref('c1'), _ref('c2')],
  );

  test('keeps everything when every photo is still available', () {
    final wrapUp = buildWrapUpEntity(
      cut: WrapUpFilmCut.compact,
      moments: [
        const WrapUpMoment(photoId: 'a'),
        collage,
      ],
    );

    final pruned = pruneMissingPhotos(wrapUp, {'a', 'c0', 'c1', 'c2'});

    expect(pruned, wrapUp);
  });

  test('removes a card-flip moment whose photo is gone', () {
    final wrapUp = buildWrapUpEntity(
      moments: const [
        WrapUpMoment(photoId: 'a'),
        WrapUpMoment(photoId: 'b'),
      ],
    );

    final pruned = pruneMissingPhotos(wrapUp, {'b'});

    expect(pruned.moments.map((m) => m.photoId), ['b']);
  });

  test('a collage missing a tile falls back to a card flip on its photo', () {
    final pruned = pruneMissingPhotos(
      buildWrapUpEntity(moments: [collage]),
      {'c0', 'c2'},
    );

    final moment = pruned.moments.single;
    expect(moment.photoId, 'c0');
    expect(moment.layout, isNull);
    expect(moment.collageExtras, isEmpty);
    expect(moment.note, 'Harbour at dusk');
    expect(moment.badge, 'Dare · Sunset · ✦2');
  });

  test('a collage whose own photo is gone flips a surviving tile instead, '
      'without the gone photo\'s note or badge', () {
    final pruned = pruneMissingPhotos(
      buildWrapUpEntity(moments: [collage]),
      {'c2'},
    );

    final moment = pruned.moments.single;
    expect(moment.photoId, 'c2');
    expect(moment.layout, isNull);
    expect(moment.note, isNull);
    expect(moment.badge, isNull);
  });

  test('a collage with no surviving tile is removed', () {
    final pruned = pruneMissingPhotos(
      buildWrapUpEntity(moments: [collage]),
      const {},
    );

    expect(pruned.moments, isEmpty);
  });

  test('flurry lists drop missing photos', () {
    final wrapUp = buildWrapUpEntity(
      cut: WrapUpFilmCut.full,
      flurryLeftovers: WrapUpFlurryLeftovers(
        photos: [_ref('f1'), _ref('f2'), _ref('f3')],
        flurry1: [_ref('f1'), _ref('f2')],
        flurry2: [_ref('f3')],
        totalRemainingLabel: 'And 12 more.',
      ),
    );

    final pruned = pruneMissingPhotos(wrapUp, {'f1', 'f3'});

    expect(pruned.flurryLeftovers.photos, [_ref('f1'), _ref('f3')]);
    expect(pruned.flurryLeftovers.flurry1, [_ref('f1')]);
    expect(pruned.flurryLeftovers.flurry2, [_ref('f3')]);
    expect(pruned.flurryLeftovers.totalRemainingLabel, 'And 12 more.');
  });
}
