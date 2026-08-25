import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/expense/presentation/widgets/expense_compare_verdict.dart';

import '../../fakes/fake_expense_repository.dart';

void main() {
  test('bigger total, no per-day data for one side: single sentence', () {
    final a = buildExpenseSummaryEntity(
      tripName: 'Iceland ring road',
      totalAmount: 2280,
      durationDays: null,
    );
    final b = buildExpenseSummaryEntity(
      tripName: 'Santorini blues',
      totalAmount: 1341,
      durationDays: 6,
    );

    expect(
      buildCompareVerdict(a: a, b: b),
      'Iceland ring road cost €939 more overall than Santorini blues.',
    );
  });

  test('the bigger-total trip also runs higher per day: "and ... too"', () {
    final a = buildExpenseSummaryEntity(
      tripName: 'A',
      totalAmount: 1000,
      durationDays: 5,
    );
    final b = buildExpenseSummaryEntity(
      tripName: 'B',
      totalAmount: 600,
      durationDays: 10,
    );

    expect(
      buildCompareVerdict(a: a, b: b),
      'A cost €400 more overall and ran €140/day higher too. B was the '
      'cheaper trip per day.',
    );
  });

  test(
    'the smaller-total trip runs higher per day: contrast with "but"',
    () {
      final a = buildExpenseSummaryEntity(
        tripName: 'A',
        totalAmount: 1000,
        durationDays: 20,
      );
      final b = buildExpenseSummaryEntity(
        tripName: 'B',
        totalAmount: 600,
        durationDays: 5,
      );

      expect(
        buildCompareVerdict(a: a, b: b),
        'A cost €400 more overall, but B ran €70/day higher. A was the '
        'cheaper trip per day.',
      );
    },
  );

  test('tied totals with a per-day difference', () {
    final a = buildExpenseSummaryEntity(
      tripName: 'A',
      totalAmount: 800,
      durationDays: 8,
    );
    final b = buildExpenseSummaryEntity(
      tripName: 'B',
      totalAmount: 800,
      durationDays: 10,
    );

    expect(
      buildCompareVerdict(a: a, b: b),
      'A and B cost about the same overall, but A ran €20/day higher. B '
      'was the cheaper trip per day.',
    );
  });

  test('tied totals with no per-day data: plain tie sentence', () {
    final a = buildExpenseSummaryEntity(
      tripName: 'A',
      totalAmount: 800,
      durationDays: null,
    );
    final b = buildExpenseSummaryEntity(
      tripName: 'B',
      totalAmount: 800,
      durationDays: null,
    );

    expect(
      buildCompareVerdict(a: a, b: b),
      'A and B cost about the same overall.',
    );
  });

  test('tied totals and tied per-day rate: plain tie sentence', () {
    final a = buildExpenseSummaryEntity(
      tripName: 'A',
      totalAmount: 800,
      durationDays: 8,
    );
    final b = buildExpenseSummaryEntity(
      tripName: 'B',
      totalAmount: 800,
      durationDays: 8,
    );

    expect(
      buildCompareVerdict(a: a, b: b),
      'A and B cost about the same overall.',
    );
  });
}
