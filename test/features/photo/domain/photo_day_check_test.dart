import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/photo_day_check.dart';

void main() {
  final start = DateTime(2026, 4, 11);
  final end = DateTime(2026, 4, 18);
  final today = DateTime(2026, 11, 25);

  DateTime? suggest(DateTime? taken, DateTime journalDay) => suggestedPhotoDay(
    captureWallClock: taken,
    journalDay: journalDay,
    start: start,
    end: end,
    today: today,
  );

  test('taken on the day it is added to: no prompt', () {
    expect(suggest(DateTime(2026, 4, 13, 14), DateTime(2026, 4, 13)), isNull);
  });

  test('the night after, before 08:00: still the evening\'s day', () {
    expect(
      suggest(DateTime(2026, 4, 14, 2, 24), DateTime(2026, 4, 13)),
      isNull,
    );
  });

  test('taken a day earlier ("Arabic retreat"): suggests its own day', () {
    expect(
      suggest(DateTime(2026, 4, 12, 9, 30), DateTime(2026, 4, 13)),
      DateTime(2026, 4, 12),
    );
    // After 08:00 the next day is a day of its own.
    expect(
      suggest(DateTime(2026, 4, 14, 9), DateTime(2026, 4, 13)),
      DateTime(2026, 4, 14),
    );
  });

  test('no capture time, or taken outside the memory: no prompt', () {
    expect(suggest(null, DateTime(2026, 4, 13)), isNull);
    expect(suggest(DateTime(2026, 4, 10, 16), DateTime(2026, 4, 11)), isNull);
    expect(suggest(DateTime(2026, 4, 20, 12), DateTime(2026, 4, 18)), isNull);
  });

  test('never a day after today (future days are locked)', () {
    expect(
      suggestedPhotoDay(
        captureWallClock: DateTime(2026, 4, 15, 12),
        journalDay: DateTime(2026, 4, 13),
        start: start,
        end: end,
        today: DateTime(2026, 4, 14),
      ),
      isNull,
    );
  });

  test('early morning after the last day: the last evening', () {
    expect(
      suggest(DateTime(2026, 4, 19, 3), DateTime(2026, 4, 12)),
      DateTime(2026, 4, 18),
    );
  });
}
