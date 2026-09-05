import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/controllers/journal_state.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_day_note_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

JournalState _stateWith({
  required DateTime? startDate,
  required DateTime? endDate,
  int photoCount = 0,
  int noteDayCount = 0,
}) {
  return JournalState(
    trip: buildTripCard(id: 't1', startDate: startDate, endDate: endDate),
    photos: [
      for (var i = 0; i < photoCount; i++) buildPhotoEntity(id: 'p$i'),
    ],
    notes: [
      for (var i = 0; i < noteDayCount; i++)
        buildDayNoteEntity(
          id: 'n$i',
          dayDate: _today.subtract(Duration(days: i)),
        ),
    ],
  );
}

void main() {
  group('wrapUpAvailability (#103)', () {
    test('is hidden when the trip has no end date', () {
      final state = _stateWith(startDate: null, endDate: null);
      expect(state.wrapUpAvailability, WrapUpAvailability.hidden);
    });

    test('is hidden while the trip has not reached its end date', () {
      final state = _stateWith(
        startDate: _today,
        endDate: _today.add(const Duration(days: 1)),
        photoCount: 5,
        noteDayCount: 5,
      );
      expect(state.wrapUpAvailability, WrapUpAvailability.hidden);
    });

    test('is locked on the end date itself with too little content', () {
      final state = _stateWith(startDate: _today, endDate: _today);
      expect(state.wrapUpAvailability, WrapUpAvailability.locked);
    });

    test('is locked once ended but under either minimum', () {
      final enoughPhotosNotEnoughNotes = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 3,
        noteDayCount: 1,
      );
      expect(
        enoughPhotosNotEnoughNotes.wrapUpAvailability,
        WrapUpAvailability.locked,
      );

      final enoughNotesNotEnoughPhotos = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 2,
        noteDayCount: 2,
      );
      expect(
        enoughNotesNotEnoughPhotos.wrapUpAvailability,
        WrapUpAvailability.locked,
      );
    });

    test('is unlocked once ended with the trip past its end date too', () {
      final state = _stateWith(
        startDate: _today.subtract(const Duration(days: 5)),
        endDate: _today.subtract(const Duration(days: 1)),
        photoCount: 3,
        noteDayCount: 2,
      );
      expect(state.wrapUpAvailability, WrapUpAvailability.unlocked);
    });
  });

  group('wrapUpLockedReason (#103)', () {
    test('is null unless locked', () {
      final hidden = _stateWith(
        startDate: _today,
        endDate: _today.add(const Duration(days: 1)),
      );
      expect(hidden.wrapUpLockedReason, isNull);

      final unlocked = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 3,
        noteDayCount: 2,
      );
      expect(unlocked.wrapUpLockedReason, isNull);
    });

    test('names both missing counts, pluralized correctly', () {
      final state = _stateWith(startDate: _today, endDate: _today);
      expect(
        state.wrapUpLockedReason,
        'Add 3 more photos and 2 more notes to unlock your wrap-up',
      );
    });

    test('names only the missing count when the other is already met', () {
      final missingOnePhoto = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 2,
        noteDayCount: 2,
      );
      expect(
        missingOnePhoto.wrapUpLockedReason,
        'Add 1 more photo to unlock your wrap-up',
      );

      final missingOneNote = _stateWith(
        startDate: _today,
        endDate: _today,
        photoCount: 3,
        noteDayCount: 1,
      );
      expect(
        missingOneNote.wrapUpLockedReason,
        'Add 1 more note to unlock your wrap-up',
      );
    });
  });
}
