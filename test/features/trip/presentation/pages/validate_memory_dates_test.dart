import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/presentation/pages/validate_memory_dates.dart';
import 'package:traviato/l10n/app_localizations.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  group('validateMemoryDates', () {
    test('requires both dates (#270)', () {
      const error = 'Add a start and end date.';
      expect(validateMemoryDates(_en, null, null), error);
      expect(validateMemoryDates(_en, DateTime(2026, 1, 1), null), error);
      expect(validateMemoryDates(_en, null, DateTime(2026, 1, 1)), error);
    });

    test(
      "doesn't flag a missing date while the form is still being filled in",
      () {
        expect(
          validateMemoryDates(
            _en,
            DateTime(2026, 1, 1),
            null,
            requireBoth: false,
          ),
          isNull,
        );
        expect(
          validateMemoryDates(_en, null, null, requireBoth: false),
          isNull,
        );
      },
    );

    test('still flags end before start while filling in', () {
      expect(
        validateMemoryDates(
          _en,
          DateTime(2026, 8, 18),
          DateTime(2026, 8, 10),
          requireBoth: false,
        ),
        "End date can't be before the start date.",
      );
    });

    test('returns null when end is on or after start', () {
      final start = DateTime(2026, 8, 18);
      expect(validateMemoryDates(_en, start, start), isNull);
      expect(validateMemoryDates(_en, start, DateTime(2026, 8, 22)), isNull);
    });

    test('returns an error when end is before start', () {
      final start = DateTime(2026, 8, 18);
      final end = DateTime(2026, 8, 10);
      expect(
        validateMemoryDates(_en, start, end),
        "End date can't be before the start date.",
      );
    });
  });
}
