import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/data/models/photo_model.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';

Map<String, dynamic> _row({Object? useInWrapUp, String? setAt}) => {
  'id': 'p1',
  'trip_id': 't1',
  'day_date': '2026-06-01',
  'storage_path': 'u1/t1/p1.jpg',
  'created_at': '2026-06-01T09:00:00Z',
  'use_in_wrap_up': useInWrapUp,
  'use_in_wrap_up_set_at': setAt,
};

void main() {
  group('PhotoModel film pick (#294)', () {
    test('null, true and false map to Auto, Always and Leave out', () {
      expect(PhotoModel.fromJson(_row()).filmPick, FilmPick.auto);
      expect(
        PhotoModel.fromJson(_row(useInWrapUp: true)).filmPick,
        FilmPick.always,
      );
      expect(
        PhotoModel.fromJson(_row(useInWrapUp: false)).filmPick,
        FilmPick.never,
      );
    });

    test('a row without the columns reads as Auto, never stamped', () {
      final photo = PhotoModel.fromJson(
        _row()
          ..remove('use_in_wrap_up')
          ..remove('use_in_wrap_up_set_at'),
      );
      expect(photo.filmPick, FilmPick.auto);
      expect(photo.filmPickSetAt, isNull);
    });

    test('parses the stamp and keeps the pick through withImageUrl', () {
      final photo = PhotoModel.fromJson(
        _row(useInWrapUp: true, setAt: '2026-06-02T10:00:00Z'),
      ).withImageUrl('https://signed');
      expect(photo.filmPick, FilmPick.always);
      expect(photo.filmPickSetAt, DateTime.utc(2026, 6, 2, 10));
    });
  });
}
