import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/controllers/initial_journal_day.dart';

void main() {
  // Fixture from the #163 report: Feb 25 – Mar 1.
  final start = DateTime(2026, 2, 25);
  final end = DateTime(2026, 3, 1);

  test('a finished memory opens on Day 1, not the last day (#163)', () {
    expect(
      initialJournalDay(
        startDate: start,
        endDate: end,
        today: DateTime(2026, 9, 29, 14, 30),
      ),
      start,
    );
  });

  test('an in-progress memory opens on today, time stripped', () {
    expect(
      initialJournalDay(
        startDate: start,
        endDate: end,
        today: DateTime(2026, 2, 27, 8, 15),
      ),
      DateTime(2026, 2, 27),
    );
  });

  test('an in-progress memory on its first and last day opens on today', () {
    expect(
      initialJournalDay(startDate: start, endDate: end, today: start),
      start,
    );
    expect(
      initialJournalDay(
        startDate: start,
        endDate: end,
        today: DateTime(2026, 3, 1, 23, 59),
      ),
      end,
    );
  });

  test('an upcoming memory opens on Day 1', () {
    expect(
      initialJournalDay(
        startDate: start,
        endDate: end,
        today: DateTime(2026, 1, 10),
      ),
      start,
    );
  });

  test('a memory without a date range has no initial day', () {
    final today = DateTime(2026, 2, 27);
    expect(
      initialJournalDay(startDate: null, endDate: end, today: today),
      isNull,
    );
    expect(
      initialJournalDay(startDate: start, endDate: null, today: today),
      isNull,
    );
  });
}
