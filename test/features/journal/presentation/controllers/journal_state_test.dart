import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_state.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_day_note_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// [currentDayDate] defaults to the trip's last day — the CTA is scoped to
/// that day only (#107), so most tests here mean to be looking at it.
JournalState _stateWith({
  required DateTime? startDate,
  required DateTime? endDate,
  int photoCount = 0,
  int noteCount = 0,
  DateTime? currentDayDate,
}) {
  return JournalState(
    trip: buildTripCard(id: 't1', startDate: startDate, endDate: endDate),
    currentDayDate: currentDayDate ?? endDate,
    photos: [
      for (var i = 0; i < photoCount; i++) buildPhotoEntity(id: 'p$i'),
    ],
    notes: [
      for (var i = 0; i < noteCount; i++)
        buildDayNoteEntity(
          id: 'n$i',
          dayDate: _today.subtract(Duration(days: i)),
        ),
    ],
  );
}

void main() {
  group('wrapUpAvailability (#103/#140)', () {
    test('is hidden when the trip has no end date', () {
      final state = _stateWith(startDate: null, endDate: null);
      expect(state.wrapUpAvailability, WrapUpAvailability.hidden);
    });

    test('is hidden while the trip has not reached its end date', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today.add(const Duration(days: 1)),
        photoCount: 5,
        noteCount: 5,
      );
      expect(state.wrapUpAvailability, WrapUpAvailability.hidden);
    });

    test('is locked on the end date itself with too little content', () {
      final state = _stateWith(startDate: _today, endDate: _today);
      expect(state.wrapUpAvailability, WrapUpAvailability.locked);
    });

    // docs/design/M6_MONETIZATION_SPEC.md §8 test matrix, implemented
    // literally (#140).
    test('3 photos, 1 note → locked (photos unmet, notes met)', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 3,
        noteCount: 1,
      );
      expect(state.wrapUpAvailability, WrapUpAvailability.locked);
      expect(state.wrapUpPhotosMet, isFalse);
      expect(state.wrapUpNotesMet, isTrue);
      expect(state.wrapUpPhotosHave, 3);
      expect(state.wrapUpNotesHave, 1);
      expect(state.wrapUpAskLine, 'Add 2 more photos to unlock it.');
    });

    test(
      '6 photos, 0 notes → locked, ask = "Write one note to unlock it."',
      () {
        final state = _stateWith(
          startDate: _today,
          endDate: _today,
          photoCount: 6,
        );
        expect(state.wrapUpAvailability, WrapUpAvailability.locked);
        expect(state.wrapUpAskLine, 'Write one note to unlock it.');
      },
    );

    test('6 photos, 1 note → unlocked, no explainer (ask line is null)', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 6,
        noteCount: 1,
      );
      expect(state.wrapUpAvailability, WrapUpAvailability.unlocked);
      expect(state.wrapUpAskLine, isNull);
    });

    test('is unlocked once ended with the trip past its end date too', () {
      final state = _stateWith(
        startDate: _today.subtract(const Duration(days: 5)),
        endDate: _today.subtract(const Duration(days: 1)),
        photoCount: 5,
        noteCount: 1,
      );
      expect(state.wrapUpAvailability, WrapUpAvailability.unlocked);
    });

    test(
      'is hidden on a non-last day even after the trip has ended and meets '
      'the content minimum (#107)',
      () {
        final start = _today.subtract(const Duration(days: 5));
        final end = _today.subtract(const Duration(days: 1));
        final state = _stateWith(
          startDate: start,
          endDate: end,
          photoCount: 5,
          noteCount: 1,
          currentDayDate: start, // first day, not the last
        );
        expect(state.wrapUpAvailability, WrapUpAvailability.hidden);
      },
    );
  });

  group('wrapUpAskLine (#140)', () {
    test('is null unless locked', () {
      final hidden = _stateWith(
        startDate: _today,
        endDate: _today.add(const Duration(days: 1)),
      );
      expect(hidden.wrapUpAskLine, isNull);

      final unlocked = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 5,
        noteCount: 1,
      );
      expect(unlocked.wrapUpAskLine, isNull);
    });

    test('names both missing counts, pluralized correctly', () {
      final state = _stateWith(startDate: _today, endDate: _today);
      expect(
        state.wrapUpAskLine,
        'Add 5 more photos and one note to unlock it.',
      );
    });

    test('singular photo count reads correctly in the "both" variant', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 4,
      );
      expect(
        state.wrapUpAskLine,
        'Add 1 more photo and one note to unlock it.',
      );
    });

    test('names only the missing photos when notes are already met', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 4,
        noteCount: 1,
      );
      expect(state.wrapUpAskLine, 'Add 1 more photo to unlock it.');
    });
  });

  group('checklist counters clamp at the requirement (#140)', () {
    test('never shows a count above what is needed', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 50, // way over the 5 needed; still locked on notes
      );
      expect(state.wrapUpPhotosHave, 5);
      expect(state.wrapUpPhotosMet, isTrue);
    });
  });

  group('isDayEmpty (#140)', () {
    test('true for a day with no photos and no note', () {
      final state = _stateWith(startDate: _today, endDate: _today);
      expect(state.isDayEmpty(_today), isTrue);
    });

    test('false once the day has a photo', () {
      final state = JournalState(
        trip: buildTripCard(id: 't1', startDate: _today, endDate: _today),
        photos: [buildPhotoEntity(id: 'p1', dayDate: _today)],
      );
      expect(state.isDayEmpty(_today), isFalse);
    });

    test('false once the day has a note', () {
      final state = JournalState(
        trip: buildTripCard(id: 't1', startDate: _today, endDate: _today),
        notes: [buildDayNoteEntity(id: 'n1', dayDate: _today)],
      );
      expect(state.isDayEmpty(_today), isFalse);
    });
  });

  group('isDayLocked (#118)', () {
    final state = _stateWith(
      startDate: _today.subtract(const Duration(days: 5)),
      endDate: _today.add(const Duration(days: 5)),
    );

    test('is false for a past day', () {
      expect(
        state.isDayLocked(_today.subtract(const Duration(days: 1))),
        isFalse,
      );
    });

    test('is false for today', () {
      expect(state.isDayLocked(_today), isFalse);
    });

    test('is true for a future day', () {
      expect(state.isDayLocked(_today.add(const Duration(days: 1))), isTrue);
    });
  });
}
