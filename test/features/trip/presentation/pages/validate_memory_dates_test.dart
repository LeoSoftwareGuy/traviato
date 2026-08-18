import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/presentation/pages/validate_memory_dates.dart';

void main() {
  group('validateMemoryDates', () {
    test('returns null when either date is missing', () {
      expect(validateMemoryDates(null, null), isNull);
      expect(validateMemoryDates(DateTime(2026, 1, 1), null), isNull);
      expect(validateMemoryDates(null, DateTime(2026, 1, 1)), isNull);
    });

    test('returns null when end is on or after start', () {
      final start = DateTime(2026, 8, 18);
      expect(validateMemoryDates(start, start), isNull);
      expect(validateMemoryDates(start, DateTime(2026, 8, 22)), isNull);
    });

    test('returns an error when end is before start', () {
      final start = DateTime(2026, 8, 18);
      final end = DateTime(2026, 8, 10);
      expect(validateMemoryDates(start, end), isNotNull);
    });
  });
}
