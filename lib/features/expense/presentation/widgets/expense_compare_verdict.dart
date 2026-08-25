import '../../domain/entities/expense_summary_entity.dart';
import 'expense_money_format.dart';

/// Computed verdict sentence for the Compare screen (`docs/design/README.md`
/// § 9, "Verdict card"). Pure — no widget/state dependency, so it's directly
/// unit-testable.
///
/// Note: the spec's illustrative example ("Santorini blues ran €16/day
/// higher... Santorini blues was the cheaper trip per day") is internally
/// contradictory as written. This implementation is the logically
/// consistent version: whichever trip has the *lower* per-day rate is the
/// one named "the cheaper trip per day".
String buildCompareVerdict({
  required ExpenseSummaryEntity a,
  required ExpenseSummaryEntity b,
}) {
  final bigger = a.totalAmount == b.totalAmount
      ? null
      : (a.totalAmount > b.totalAmount ? a : b);
  final smaller = bigger == null ? null : (bigger == a ? b : a);
  final totalDiff = (a.totalAmount - b.totalAmount).abs();

  final perDayA = a.perDay;
  final perDayB = b.perDay;
  ExpenseSummaryEntity? higherPerDay;
  var perDayDiff = 0.0;
  if (perDayA != null && perDayB != null && perDayA != perDayB) {
    higherPerDay = perDayA > perDayB ? a : b;
    perDayDiff = (perDayA - perDayB).abs();
  }
  final cheaperPerDay = higherPerDay == null
      ? null
      : (higherPerDay == a ? b : a);

  if (bigger == null) {
    if (higherPerDay == null) {
      return '${a.tripName} and ${b.tripName} cost about the same overall.';
    }
    return '${a.tripName} and ${b.tripName} cost about the same overall, '
        'but ${higherPerDay.tripName} ran ${formatEuro(perDayDiff)}/day '
        'higher. ${cheaperPerDay!.tripName} was the cheaper trip per day.';
  }

  if (higherPerDay == null) {
    return '${bigger.tripName} cost ${formatEuro(totalDiff)} more overall '
        'than ${smaller!.tripName}.';
  }

  if (higherPerDay == bigger) {
    return '${bigger.tripName} cost ${formatEuro(totalDiff)} more overall '
        'and ran ${formatEuro(perDayDiff)}/day higher too. '
        '${cheaperPerDay!.tripName} was the cheaper trip per day.';
  }

  return '${bigger.tripName} cost ${formatEuro(totalDiff)} more overall, '
      'but ${higherPerDay.tripName} ran ${formatEuro(perDayDiff)}/day '
      'higher. ${cheaperPerDay!.tripName} was the cheaper trip per day.';
}
