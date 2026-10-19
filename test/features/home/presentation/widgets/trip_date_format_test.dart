import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/home/presentation/widgets/trip_date_format.dart';
import 'package:traviato/l10n/app_localizations.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _ru = lookupAppLocalizations(const Locale('ru'));

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  group('tripDateRangeLabel', () {
    test('a single day shows one date, not a range (#186)', () {
      expect(
        tripDateRangeLabel(_en, DateTime(2026, 8, 12), DateTime(2026, 8, 12)),
        'Aug 12',
      );
    });

    test('a multi-day trip shows the range', () {
      expect(
        tripDateRangeLabel(_en, DateTime(2026, 8, 12), DateTime(2026, 8, 16)),
        'Aug 12 – Aug 16',
      );
    });
  });

  group('tripDayOfLabel', () {
    test('a single-day trip reads "Today" (#186)', () {
      expect(tripDayOfLabel(_en, _today, _today), 'Today');
    });

    test('a multi-day trip reads "Day X of Y"', () {
      expect(
        tripDayOfLabel(
          _en,
          _today.subtract(const Duration(days: 1)),
          _today.add(const Duration(days: 1)),
        ),
        'Day 2 of 3',
      );
    });
  });
  group('in ru (#220)', () {
    final aug12 = DateTime(2026, 8, 12);
    final aug16 = DateTime(2026, 8, 16);

    test('date ranges use the locale order and month names', () {
      expect(tripDateRangeLabel(_ru, aug12, aug16), '12 авг. – 16 авг.');
      expect(tripDateRangeLabel(_ru, null, null), 'Даты не выбраны');
    });

    test('day pill follows the spec abbreviations', () {
      final yesterday = _today.subtract(const Duration(days: 1));
      final tomorrow = _today.add(const Duration(days: 3));
      expect(tripDayOfLabel(_ru, yesterday, tomorrow), 'День 2 из 5');
    });

    test('countdown pill', () {
      final inFour = _today.add(const Duration(days: 4));
      expect(tripCountdownLabel(_en, inFour), 'in 4d');
      expect(tripCountdownLabel(_ru, inFour), 'через 4 дн.');
    });
  });
}
