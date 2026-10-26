import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/kept_film_staleness.dart';

import '../../photo/fakes/fake_photo_repository.dart';
import '../fakes/fake_wrap_up_repository.dart';

final _builtAt = DateTime.utc(2026, 6, 10, 12);

final _kept = buildWrapUpEntity(
  cut: WrapUpFilmCut.compact,
  generatedAt: _builtAt,
  publishedAt: DateTime.utc(2026, 6, 10, 13),
  moments: const [WrapUpMoment(photoId: 'p1')],
  flurryLeftovers: const WrapUpFlurryLeftovers(
    flurry1: [WrapUpPhotoRef(photoId: 'p2')],
  ),
);

void main() {
  group('isKeptFilmOutOfDate (#294)', () {
    test('an untouched kept film is up to date', () {
      final photos = [
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(
          id: 'p2',
          filmPick: FilmPick.always,
          filmPickSetAt: _builtAt.subtract(const Duration(hours: 1)),
        ),
      ];
      expect(isKeptFilmOutOfDate(_kept, photos), isFalse);
    });

    test('a pick changed after the film was built makes it out of date', () {
      final photos = [
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(
          id: 'p2',
          filmPick: FilmPick.never,
          filmPickSetAt: _builtAt.add(const Duration(minutes: 1)),
        ),
      ];
      expect(isKeptFilmOutOfDate(_kept, photos), isTrue);
    });

    test('a deleted photo the film shows makes it out of date', () {
      expect(isKeptFilmOutOfDate(_kept, [buildPhotoEntity(id: 'p1')]), isTrue);
    });

    test('a draft is never out of date — it rebuilds on every open', () {
      final draft = buildWrapUpEntity(
        generatedAt: _builtAt,
        moments: const [WrapUpMoment(photoId: 'gone')],
      );
      expect(isKeptFilmOutOfDate(draft, const []), isFalse);
    });
  });
}
