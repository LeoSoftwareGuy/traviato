import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/domain/day_timeline.dart';
import 'package:traviato/features/journal/domain/entities/journal_note_entity.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';

import '../../photo/fakes/fake_photo_repository.dart';
import '../fakes/fake_journal_note_repository.dart';

final _day = DateTime(2026, 10, 23);

DateTime _at(int hour, int minute, {int day = 23}) =>
    DateTime(2026, 10, day, hour, minute);

PhotoEntity _photo(String id, DateTime at, {String? caption}) =>
    buildPhotoEntity(id: id, dayDate: _day, takenAt: at, caption: caption);

JournalNoteEntity _note(String id, DateTime at, {bool legacy = false}) =>
    buildJournalNoteEntity(
      id: id,
      dayDate: _day,
      createdAt: at,
      legacy: legacy,
    );

/// A row as a short label: "p 06:40+06:42", "n 06:45", "—", "later".
String _label(TimelineEntry e) => switch (e) {
  TimelinePhotoRow(:final photos) =>
    'p ${photos.map((p) => _hm(p.takenAt!)).join('+')}',
  TimelineNoteRow(:final note) => 'n ${_hm(note.takenAt)}',
  TimelineAfterMidnight() => '—',
  TimelineLater() => 'later',
};

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void main() {
  test('spec §10.1: the Amsterdam Day 1 order', () {
    final photos = [
      _photo('a', _at(6, 40)),
      _photo('b', _at(6, 42)),
      _photo('c', _at(6, 50)),
      _photo('d', _at(10, 10)),
      _photo('e', _at(11, 25)),
      _photo('f', _at(12, 31)),
      _photo('g', _at(15, 42)),
      _photo('h', _at(18, 25)),
      _photo('i', _at(19, 30)),
      _photo('j', _at(22, 46)),
      _photo('k', _at(1, 4, day: 24)),
      _photo('l', _at(4, 34, day: 24)),
    ];
    final notes = [
      _note('n1', _at(6, 45)),
      _note('n2', _at(10, 30)),
      _note('n3', _at(14, 40)),
      _note('n4', _at(21, 16)),
      _note('n5', _at(23, 30)),
      _note('n6', _at(1, 10, day: 24)),
    ];
    final rows = buildDayTimeline(day: _day, photos: photos, notes: notes);
    expect(rows.map(_label), [
      'p 06:40+06:42',
      'n 06:45',
      'p 06:50',
      'p 10:10',
      'n 10:30',
      'p 11:25',
      'p 12:31',
      'n 14:40',
      'p 15:42',
      'p 18:25',
      'p 19:30',
      'n 21:16',
      'p 22:46',
      'n 23:30',
      '—',
      'p 01:04',
      'n 01:10',
      'p 04:34',
    ]);
    final divider = rows.whereType<TimelineAfterMidnight>().single;
    expect(divider.date, DateTime(2026, 10, 24));
  });

  test('spec §10.15: ≤ 20 min share a row; a note between splits it', () {
    expect(
      buildDayTimeline(
        day: _day,
        photos: [
          _photo('a', _at(9, 0)),
          _photo('b', _at(9, 20)),
          _photo('c', _at(9, 41)),
        ],
        notes: const [],
      ).map(_label),
      ['p 09:00+09:20', 'p 09:41'],
    );
    expect(
      buildDayTimeline(
        day: _day,
        photos: [_photo('a', _at(9, 0)), _photo('b', _at(9, 10))],
        notes: [_note('n', _at(9, 5))],
      ).map(_label),
      ['p 09:00', 'n 09:05', 'p 09:10'],
    );
  });

  test('a photo and a note at the same minute: the photo first', () {
    expect(
      buildDayTimeline(
        day: _day,
        photos: [_photo('a', _at(9, 0))],
        notes: [_note('n', _at(9, 0))],
      ).map(_label),
      ['p 09:00', 'n 09:00'],
    );
  });

  test('two notes in a row are two rows (spec §10.5)', () {
    expect(
      buildDayTimeline(
        day: _day,
        photos: const [],
        notes: [_note('n1', _at(20, 1)), _note('n2', _at(20, 2))],
      ).map(_label),
      ['n 20:01', 'n 20:02'],
    );
  });

  test('written after the day was over: at the end, after "later"', () {
    // A legacy note last edited three days on, and a note from 09:00 the
    // next morning; a 07:30 next-morning note still belongs to the night.
    final rows = buildDayTimeline(
      day: _day,
      photos: [_photo('a', _at(12, 0))],
      notes: [
        _note('old', _at(22, 14, day: 26), legacy: true),
        _note('morning', _at(9, 0, day: 24)),
        _note('late', _at(7, 30, day: 24)),
      ],
    );
    expect(rows.map(_label), [
      'p 12:00',
      '—',
      'n 07:30',
      'later',
      'n 09:00',
      'n 22:14',
    ]);
    expect(
      rows.whereType<TimelineNoteRow>().map((r) => r.isLater),
      [false, true, true],
    );
  });

  test('an empty day has no rows', () {
    expect(
      buildDayTimeline(day: _day, photos: const [], notes: const []),
      isEmpty,
    );
  });

  group('dayForNewItem', () {
    final thu = DateTime(2026, 10, 23);
    final fri = DateTime(2026, 10, 24);

    test('on today\'s tab after midnight, a night out stays on Thursday', () {
      expect(
        dayForNewItem(
          selectedDay: fri,
          now: _at(1, 10, day: 24),
          previousAt: _at(22, 46),
          previousDay: thu,
        ),
        thu,
      );
    });

    test("on the logical day's tab it stays there", () {
      expect(
        dayForNewItem(
          selectedDay: thu,
          now: _at(1, 10, day: 24),
          previousAt: _at(22, 46),
          previousDay: thu,
        ),
        thu,
      );
    });

    test("an earlier day's tab keeps its own day (written later)", () {
      expect(
        dayForNewItem(
          selectedDay: DateTime(2026, 10, 21),
          now: _at(14, 2, day: 24),
        ),
        DateTime(2026, 10, 21),
      );
    });

    test('a daytime note on today goes on today', () {
      expect(dayForNewItem(selectedDay: fri, now: _at(14, 0, day: 24)), fri);
    });
  });

  group('a backfilled note (#468)', () {
    JournalNoteEntity typedLater(String id, DateTime at) => JournalNoteEntity(
      id: id,
      tripId: 't1',
      dayDate: _day,
      takenAt: at.toUtc(),
      editedAt: at.toUtc(),
      content: 'Mosque',
      utcOffsetMinutes: 120,
    );

    test('typed more than 24 h after its day is backfilled', () {
      expect(
        typedLater('n', DateTime.utc(2026, 11, 24, 18)).isBackfilled,
        isTrue,
      );
      // The next morning or evening: still about the day.
      expect(
        typedLater('n', DateTime.utc(2026, 10, 24, 18)).isBackfilled,
        isFalse,
      );
      expect(
        typedLater('n', DateTime.utc(2026, 10, 23, 9)).isBackfilled,
        isFalse,
      );
      // A legacy note never is.
      expect(
        buildJournalNoteEntity(
          id: 'l',
          dayDate: _day,
          createdAt: DateTime(2026, 12, 1),
          legacy: true,
        ).isBackfilled,
        isFalse,
      );
    });

    test('it sits at the end of its day, after the photos', () {
      final rows = buildDayTimeline(
        day: _day,
        photos: [_photo('a', _at(10, 0)), _photo('b', _at(18, 0))],
        notes: [typedLater('late', DateTime.utc(2026, 11, 24, 18))],
      );
      expect(rows.first, isA<TimelinePhotoRow>());
      expect(rows.whereType<TimelineLater>(), hasLength(1));
      final last = rows.last as TimelineNoteRow;
      expect(last.note.id, 'late');
      expect(last.isLater, isTrue);
    });
  });
}
