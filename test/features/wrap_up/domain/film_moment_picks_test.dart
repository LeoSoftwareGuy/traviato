import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/wrap_up/domain/film_moment_picks.dart';

import '../../photo/fakes/fake_photo_repository.dart';

/// 20 photos over 5 days, c0..c19 in time order — the same shape as the
/// `#294` cases in generate_wrap_up/assemble.test.ts, so both copies of
/// the selection rule are held to the same answers.
List<PhotoEntity> _photos([Map<int, FilmPick> picks = const {}]) => [
  for (var i = 0; i < 20; i++)
    buildPhotoEntity(
      id: 'c$i',
      dayDate: DateTime(2026, 6, 1 + i ~/ 4),
      takenAt: DateTime.utc(2026, 6, 1 + i ~/ 4, 8 + i % 4),
      filmPick: picks[i] ?? FilmPick.auto,
    ),
];

List<String> _ids(Set<String> ids) =>
    ids.toList()
      ..sort((a, b) => int.parse(a.substring(1)) - int.parse(b.substring(1)));

void main() {
  group('filmMomentPhotoIds (#294)', () {
    test('all on Auto spreads the moments over the trip', () {
      final ids = filmMomentPhotoIds(photos: _photos(), bonusPhotoIds: []);
      expect(_ids(ids), ['c1', 'c3', 'c6', 'c8', 'c11', 'c13', 'c16', 'c18']);
    });

    test('scrambled input gives the same picks', () {
      final ids = filmMomentPhotoIds(
        photos: _photos().reversed.toList(),
        bonusPhotoIds: [],
      );
      expect(_ids(ids), ['c1', 'c3', 'c6', 'c8', 'c11', 'c13', 'c16', 'c18']);
    });

    test('3 Always photos all get moments, Auto fills the rest', () {
      final ids = filmMomentPhotoIds(
        photos: _photos({
          0: FilmPick.always,
          9: FilmPick.always,
          19: FilmPick.always,
        }),
        bonusPhotoIds: [],
      );
      expect(ids, hasLength(8));
      expect(ids, containsAll(['c0', 'c9', 'c19']));
    });

    test('10 Always photos take all 8 moments', () {
      final always = {for (var i = 0; i < 20; i += 2) i: FilmPick.always};
      final ids = filmMomentPhotoIds(
        photos: _photos(always),
        bonusPhotoIds: [],
      );
      expect(ids, hasLength(8));
      expect(
        ids.every((id) => always.containsKey(int.parse(id.substring(1)))),
        isTrue,
      );
    });

    test('Leave out photos are never picked', () {
      final ids = filmMomentPhotoIds(
        photos: _photos({for (var i = 2; i < 18; i++) i: FilmPick.never}),
        bonusPhotoIds: ['c5'],
      );
      expect(_ids(ids), ['c0', 'c1', 'c18', 'c19']);
    });

    test('bonus photos take moments ahead of Auto ones, up to the slots '
        'Always leaves', () {
      expect(
        filmMomentPhotoIds(photos: _photos(), bonusPhotoIds: ['c4']),
        contains('c4'),
      );

      final always = {
        for (final i in [0, 3, 6, 9, 12, 15, 18]) i: FilmPick.always,
      };
      final ids = filmMomentPhotoIds(
        photos: _photos(always),
        bonusPhotoIds: ['c10', 'c11'],
      );
      expect(
        ids.where((id) => !always.containsKey(int.parse(id.substring(1)))),
        ['c10'],
      );
    });

    test('only the first 3 bonus photos count as bonus', () {
      final ids = filmMomentPhotoIds(
        photos: _photos().take(4).toList(),
        bonusPhotoIds: ['c0', 'c1', 'c2', 'c3'],
      );
      expect(_ids(ids), ['c0', 'c1', 'c2', 'c3']);
    });

    test('no photos, no picks', () {
      expect(filmMomentPhotoIds(photos: [], bonusPhotoIds: ['x']), isEmpty);
    });
  });

  test('spreadEvenly keeps order and covers the whole list', () {
    final list = List.generate(15, (i) => i);
    expect(spreadEvenly(list, 8), [0, 2, 4, 6, 8, 10, 12, 14]);
    expect(spreadEvenly(list, 3), [2, 7, 12]);
    expect(spreadEvenly([1, 2], 8), [1, 2]);
    expect(spreadEvenly(list, 0), isEmpty);
  });
}
