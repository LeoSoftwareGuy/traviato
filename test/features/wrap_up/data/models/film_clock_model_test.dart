import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/film_clock_model.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_clock.dart';

void main() {
  test('content.local_times → each photo and note on its own clock', () {
    final clock = parseFilmClock({
      'local_times': {
        'zone': 'Europe/Budapest',
        'photos': {'p1': 60, 'p2': 120, 'bad': 'x', 'far': 9999},
        'notes': {'n1': 60},
        'zone_source': 'destination',
        'zone_detail': 'budapest',
        'photo_sources': {'place': 2},
        'note_sources': {'place': 1},
      },
    });
    expect(clock.zone, 'Europe/Budapest');
    expect(clock.isPlaceClock, isTrue);
    expect((clock.zoneSource, clock.zoneDetail), ('destination', 'budapest'));
    expect(clock.photoSources, {'place': 2});
    expect(clock.noteSources, {'place': 1});
    expect(clock.photoOffsets, {'p1': 60, 'p2': 120});
    final instant = DateTime.utc(2026, 2, 26, 20, 57, 40);
    // Budapest 21:57, though the phone may be in Tallinn (#461).
    expect(FilmClock.hhmm(clock.photo('p1', instant)), '21:57');
    expect(FilmClock.hhmm(clock.photo('p2', instant)), '22:57');
    expect(FilmClock.hhmm(clock.note('n1', instant)), '21:57');
  });

  test("a film kept before #461 plays on the phone's clock", () {
    final clock = parseFilmClock(const {});
    expect(clock, FilmClock.phone);
    expect(clock.isPlaceClock, isFalse);
    final instant = DateTime.utc(2026, 2, 26, 20, 57);
    expect(clock.photo('p1', instant), instant.toLocal());
    expect(clock.note(null, instant), instant.toLocal());
  });
}
