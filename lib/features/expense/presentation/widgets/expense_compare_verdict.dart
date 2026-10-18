import '../../../../core/l10n/context_l10n.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../controllers/expense_compare_state.dart';
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
  required AppLocalizations l10n,
  required ExpenseSummaryEntity a,
  required ExpenseSummaryEntity b,
}) {
  String euro(double amount) => formatEuro(amount, l10n.localeName);

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
      return l10n.compare_verdictSame(a.tripName, b.tripName);
    }
    return l10n.compare_verdictSameButPerDay(
      a.tripName,
      b.tripName,
      higherPerDay.tripName,
      euro(perDayDiff),
      cheaperPerDay!.tripName,
    );
  }

  if (higherPerDay == null) {
    return l10n.compare_verdictMore(
      bigger.tripName,
      euro(totalDiff),
      smaller!.tripName,
    );
  }

  if (higherPerDay == bigger) {
    return l10n.compare_verdictMoreAndPerDay(
      bigger.tripName,
      euro(totalDiff),
      euro(perDayDiff),
      cheaperPerDay!.tripName,
    );
  }

  return l10n.compare_verdictMoreButPerDay(
    bigger.tripName,
    euro(totalDiff),
    higherPerDay.tripName,
    euro(perDayDiff),
    cheaperPerDay!.tripName,
  );
}

/// The Compare screen's hint line under the title, in the UI language.
String compareHintLine(AppLocalizations l10n, ExpenseCompareState state) =>
    switch (state.step) {
      CompareStep.pickFirst => l10n.compare_hintPickTwo,
      CompareStep.pickSecond => l10n.compare_hintPickSecond,
      CompareStep.ready => l10n.compare_hintReady(
        state.summaryA!.tripName,
        state.summaryB!.tripName,
      ),
    };
