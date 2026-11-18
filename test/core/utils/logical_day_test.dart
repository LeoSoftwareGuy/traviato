import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/utils/logical_day.dart';

void main() {
  final thu = DateTime(2026, 10, 23);
  final fri = DateTime(2026, 10, 24);

  /// Puts each time on its logical day, in order, as saving them would.
  List<DateTime> days(List<DateTime> times) {
    final out = <DateTime>[];
    for (var i = 0; i < times.length; i++) {
      out.add(
        logicalDayOf(
          times[i],
          previousAt: i == 0 ? null : times[i - 1],
          previousDay: i == 0 ? null : out[i - 1],
        ),
      );
    }
    return out;
  }

  test('a club night stays on the evening it started', () {
    expect(
      days([
        DateTime(2026, 10, 23, 22, 46),
        DateTime(2026, 10, 24, 1, 4),
        DateTime(2026, 10, 24, 4, 34),
        DateTime(2026, 10, 24, 6, 30),
      ]),
      [thu, thu, thu, thu],
    );
  });

  test('03:00 after a 6 h gap starts a new day', () {
    expect(
      days([DateTime(2026, 10, 23, 21), DateTime(2026, 10, 24, 3)]),
      [thu, fri],
    );
  });

  test('exactly 4 h is a gap', () {
    expect(
      days([DateTime(2026, 10, 23, 23), DateTime(2026, 10, 24, 3)]),
      [thu, fri],
    );
    expect(
      days([DateTime(2026, 10, 23, 23), DateTime(2026, 10, 24, 2, 59)]),
      [thu, thu],
    );
  });

  test('from 08:00 an item always starts its own day', () {
    expect(
      days([DateTime(2026, 10, 24, 6, 30), DateTime(2026, 10, 24, 8)]),
      [fri, fri],
    );
    expect(
      days([DateTime(2026, 10, 24, 7, 59), DateTime(2026, 10, 24, 8, 5)]),
      [fri, fri],
    );
    expect(
      days([
        DateTime(2026, 10, 23, 22),
        DateTime(2026, 10, 24, 7, 59),
        DateTime(2026, 10, 24, 8, 1),
      ]),
      [thu, fri, fri],
      reason: '07:59 is still 4 h+ after 22:00, so it starts Friday',
    );
  });

  test('an early item after a new day began stays on that new day', () {
    // 01:00 starts Friday (long gap); 03:00 follows it within 4 h.
    expect(
      days([
        DateTime(2026, 10, 23, 18),
        DateTime(2026, 10, 24, 1),
        DateTime(2026, 10, 24, 3),
      ]),
      [thu, fri, fri],
    );
  });

  test('the first item of a trip is on its calendar date', () {
    expect(logicalDayOf(DateTime(2026, 10, 24, 2)), fri);
  });

  test('a previous item after this one is ignored', () {
    expect(
      logicalDayOf(
        DateTime(2026, 10, 24, 2),
        previousAt: DateTime(2026, 10, 24, 3),
        previousDay: thu,
      ),
      fri,
    );
  });

  test('a previous day that is not this night never applies', () {
    expect(
      logicalDayOf(
        DateTime(2026, 10, 24, 2),
        previousAt: DateTime(2026, 10, 24, 1),
        previousDay: DateTime(2026, 10, 20),
      ),
      fri,
    );
  });

  test('isAfterMidnightOf: the divider goes before next-date items', () {
    expect(isAfterMidnightOf(DateTime(2026, 10, 24, 1, 4), thu), isTrue);
    expect(isAfterMidnightOf(DateTime(2026, 10, 23, 23, 30), thu), isFalse);
  });
}
