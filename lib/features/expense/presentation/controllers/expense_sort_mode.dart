/// Sort options for the "Memories" list (`docs/design/README.md` § 8 — a
/// 2-state toggle pill, not a dropdown). `latestFirst` is the default and
/// does no client-side re-sort at all — it passes `summaries` through in
/// whatever order `getSummaries()` already returns them, per the spec's
/// "do not sort by amount unless the sort pill is toggled".
///
/// Labels are translated in presentation (`expenseSortLabel`, #220).
enum ExpenseSortMode { latestFirst, biggestSpender }
