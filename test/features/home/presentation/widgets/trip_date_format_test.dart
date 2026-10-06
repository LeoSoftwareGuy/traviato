import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/home/presentation/widgets/trip_date_format.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  group('tripDateRangeLabel', () {
    test('a single day shows one date, not a range (#186)', () {
      expect(
        tripDateRangeLabel(DateTime(2026, 8, 12), DateTime(2026, 8, 12)),
        'Aug 12',
      );
    });

    test('a multi-day trip shows the range', () {
      expect(
        tripDateRangeLabel(DateTime(2026, 8, 12), DateTime(2026, 8, 16)),
        'Aug 12 – Aug 16',
      );
    });
  });

  group('tripDayOfLabel', () {
    test('a single-day trip reads "Today" (#186)', () {
      expect(tripDayOfLabel(_today, _today), 'Today');
    });

    test('a multi-day trip reads "Day X of Y"', () {
      expect(
        tripDayOfLabel(
          _today.subtract(const Duration(days: 1)),
          _today.add(const Duration(days: 1)),
        ),
        'Day 2 of 3',
      );
    });
  });
}
