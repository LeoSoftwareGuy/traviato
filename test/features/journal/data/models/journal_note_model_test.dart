import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/data/models/journal_note_model.dart';

void main() {
  test('fromJson reads a timed note with its photo', () {
    final note = JournalNoteModel.fromJson({
      'id': 'n1',
      'trip_id': 't1',
      'day_date': '2026-10-23',
      'taken_at': '2026-10-23T19:16:00Z',
      'edited_at': '2026-10-23T19:20:00Z',
      'content': 'Ribs at the bar.',
      'dictated': true,
      'photo_id': 'p1',
      'legacy': false,
    });
    expect(note.dayDate, DateTime(2026, 10, 23));
    expect(note.takenAt, DateTime.utc(2026, 10, 23, 19, 16));
    expect(note.editedAt, DateTime.utc(2026, 10, 23, 19, 20));
    expect(note.dictated, isTrue);
    expect(note.photoId, 'p1');
    expect(note.legacy, isFalse);
  });

  test('fromJson: a legacy note without a photo', () {
    final note = JournalNoteModel.fromJson({
      'id': 'n1',
      'trip_id': 't1',
      'day_date': '2026-10-23',
      'taken_at': '2026-10-23T22:14:00Z',
      'edited_at': '2026-10-23T22:14:00Z',
      'content': 'Bikes everywhere.',
      'dictated': false,
      'photo_id': null,
      'legacy': true,
    });
    expect(note.photoId, isNull);
    expect(note.legacy, isTrue);
  });
}
