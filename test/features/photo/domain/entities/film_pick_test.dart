import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/entities/film_pick.dart';

void main() {
  test('FilmPick round-trips through the use_in_wrap_up column (#294)', () {
    for (final pick in FilmPick.values) {
      expect(FilmPick.fromColumn(pick.columnValue), pick);
    }
    expect(FilmPick.auto.columnValue, isNull);
    expect(FilmPick.always.columnValue, isTrue);
    expect(FilmPick.never.columnValue, isFalse);
  });
}
