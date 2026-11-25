import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/domain/note_time.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';

PhotoEntity _photo(String id, DateTime day, int? offset) => PhotoEntity(
  id: id,
  tripId: 't1',
  dayDate: day,
  storagePath: 'u/t/$id.jpg',
  createdAt: DateTime.utc(2026, 11, 24),
  utcOffsetMinutes: offset,
);

void main() {
  final day = DateTime(2026, 4, 13);

  test("the day's photos' offset, the most common one", () {
    expect(
      noteOffsetForDay(
        day: day,
        photos: [
          _photo('a', day, 240),
          _photo('b', day, 240),
          _photo('c', day, 180),
          _photo('d', DateTime(2026, 4, 14), 0),
        ],
        zone: null,
        fallbackMinutes: 120,
      ),
      240,
    );
  });

  test("no timed photo that day: the memory's zone, else the phone's", () {
    expect(
      noteOffsetForDay(
        day: day,
        photos: [_photo('a', day, null)],
        zone: 'Asia/Muscat',
        fallbackMinutes: 120,
      ),
      240,
    );
    expect(
      noteOffsetForDay(
        day: day,
        photos: const [],
        zone: null,
        fallbackMinutes: 120,
      ),
      120,
    );
  });

  test('14:30 on its day at +4 is 10:30 UTC', () {
    expect(
      noteInstantOn(day: day, hour: 14, minute: 30, offsetMinutes: 240),
      DateTime.utc(2026, 4, 13, 10, 30),
    );
  });
}
