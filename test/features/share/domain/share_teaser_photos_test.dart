import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/share/domain/share_teaser_photos.dart';

import '../../photo/fakes/fake_photo_repository.dart';

/// 20 photos over 5 days, c0..c19 in time order (the film-picks shape).
List<PhotoEntity> _photos([Map<int, FilmPick> picks = const {}]) => [
  for (var i = 0; i < 20; i++)
    buildPhotoEntity(
      id: 'c$i',
      storagePath: 'u/t/c$i.jpg',
      dayDate: DateTime(2026, 6, 1 + i ~/ 4),
      takenAt: DateTime.utc(2026, 6, 1 + i ~/ 4, 8 + i % 4),
      filmPick: picks[i] ?? FilmPick.auto,
    ),
];

List<String> _ids(List<PhotoEntity> photos) => [for (final p in photos) p.id];

void main() {
  group('shareTeaserPhotos (#309)', () {
    test('all on Auto: the film moment picks, chronological, 6 of them', () {
      final teaser = shareTeaserPhotos(photos: _photos(), bonusPhotoIds: []);
      expect(teaser, hasLength(shareTeaserPhotoCount));
      // The 16-moment film picks every photo but c2, c7, c12, c17.
      expect(_ids(teaser), ['c0', 'c1', 'c3', 'c4', 'c5', 'c6']);
    });

    test('Always picks come first, chronological, then moment picks', () {
      final teaser = shareTeaserPhotos(
        photos: _photos({19: FilmPick.always, 12: FilmPick.always}),
        bonusPhotoIds: [],
      );
      expect(_ids(teaser).take(2), ['c12', 'c19']);
    });

    test('Leave-out photos never appear', () {
      final teaser = shareTeaserPhotos(
        photos: _photos({for (var i = 0; i < 18; i++) i: FilmPick.never}),
        bonusPhotoIds: [],
      );
      expect(_ids(teaser), ['c18', 'c19']);
    });

    test('the cover photo goes first when it is eligible', () {
      final teaser = shareTeaserPhotos(
        photos: _photos({0: FilmPick.always}),
        bonusPhotoIds: [],
        coverImagePath: 'u/t/c17.jpg',
      );
      expect(_ids(teaser).take(2), ['c17', 'c0']);
    });

    test('a left-out cover is not used', () {
      final teaser = shareTeaserPhotos(
        photos: _photos({17: FilmPick.never}),
        bonusPhotoIds: [],
        coverImagePath: 'u/t/c17.jpg',
      );
      expect(_ids(teaser), isNot(contains('c17')));
    });

    test('a bundled cover changes nothing', () {
      expect(
        _ids(
          shareTeaserPhotos(
            photos: _photos(),
            bonusPhotoIds: [],
            coverImagePath: 'asset:mountains',
          ),
        ),
        _ids(shareTeaserPhotos(photos: _photos(), bonusPhotoIds: [])),
      );
    });

    test('no photos → empty', () {
      expect(shareTeaserPhotos(photos: [], bonusPhotoIds: []), isEmpty);
    });
  });
}
