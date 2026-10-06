import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_date_labels.dart';

void main() {
  group('formatWrapUpDateRange', () {
    test('single day', () {
      expect(
        formatWrapUpDateRange(DateTime(2026, 8, 12), DateTime(2026, 8, 12)),
        '12 August 2026',
      );
    });

    test('same month', () {
      expect(
        formatWrapUpDateRange(DateTime(2026, 8, 12), DateTime(2026, 8, 16)),
        '12–16 August 2026',
      );
    });

    test('cross-month', () {
      expect(
        formatWrapUpDateRange(DateTime(2026, 2, 25), DateTime(2026, 3, 1)),
        '25 February – 1 March 2026',
      );
    });

    test('cross-year shows both years', () {
      expect(
        formatWrapUpDateRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
        '30 December 2026 – 2 January 2027',
      );
    });

    test('only one date known', () {
      expect(
        formatWrapUpDateRange(DateTime(2026, 8, 12), null),
        '12 August 2026',
      );
      expect(
        formatWrapUpDateRange(null, DateTime(2026, 8, 12)),
        '12 August 2026',
      );
    });

    test('no dates → null', () {
      expect(formatWrapUpDateRange(null, null), isNull);
    });
  });

  group('wrapUpDayCountLine', () {
    test('one day is singular', () {
      expect(
        wrapUpDayCountLine(DateTime(2026, 8, 12), DateTime(2026, 8, 12)),
        'One day.',
      );
    });

    test('number words up to twenty', () {
      expect(
        wrapUpDayCountLine(DateTime(2026, 8, 12), DateTime(2026, 8, 16)),
        'Five days.',
      );
      expect(
        wrapUpDayCountLine(DateTime(2026, 8, 1), DateTime(2026, 8, 20)),
        'Twenty days.',
      );
    });

    test('digits past twenty', () {
      expect(
        wrapUpDayCountLine(DateTime(2026, 8, 1), DateTime(2026, 8, 21)),
        '21 days.',
      );
    });

    test('missing or inverted dates → null', () {
      expect(wrapUpDayCountLine(DateTime(2026, 8, 12), null), isNull);
      expect(
        wrapUpDayCountLine(DateTime(2026, 8, 12), DateTime(2026, 8, 11)),
        isNull,
      );
    });
  });
}
