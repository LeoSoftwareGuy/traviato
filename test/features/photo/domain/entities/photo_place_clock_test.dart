import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/domain/entities/journal_note_entity.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';

void main() {
  final instant = DateTime.utc(2026, 2, 26, 20, 57, 40);

  PhotoEntity photo({int? offset}) => PhotoEntity(
    id: 'p1',
    tripId: 't1',
    storagePath: 'p1.jpg',
    takenAt: instant,
    createdAt: DateTime.utc(2026, 11, 22),
    utcOffsetMinutes: offset,
  );

  test("an old photo reads on the memory's zone (#461)", () {
    final p = photo().onClockOf('Europe/Budapest');
    expect(p.utcOffsetMinutes, 60);
    expect((p.localTime.hour, p.localTime.minute), (21, 57));
  });

  test('its own offset wins over the memory zone', () {
    final p = photo(offset: 120).onClockOf('Europe/Budapest');
    expect(p.utcOffsetMinutes, 120);
    expect(p.localTime.hour, 22);
  });

  test("no zone found: the phone's clock", () {
    final p = photo().onClockOf(null);
    expect(p.utcOffsetMinutes, isNull);
    expect(p.localTime, instant.toLocal());
  });

  test("a note without an offset reads on the memory's zone", () {
    final n = JournalNoteEntity(
      id: 'n1',
      tripId: 't1',
      dayDate: DateTime(2026, 2, 26),
      takenAt: instant,
      editedAt: instant,
      content: 'Dinner by the river.',
    ).onClockOf('Europe/Budapest');
    expect(n.utcOffsetMinutes, 60);
    expect(n.localTakenAt.hour, 21);
    expect(n.content, 'Dinner by the river.');
  });
}
