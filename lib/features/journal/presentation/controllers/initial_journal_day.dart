/// The day the Journal opens on (#163): today while the memory is under way,
/// otherwise Day 1 — both for a finished memory and a not-yet-started one.
/// `null` when the memory has no date range. [today] is injected so the rule
/// is testable without a clock.
DateTime? initialJournalDay({
  required DateTime? startDate,
  required DateTime? endDate,
  required DateTime today,
}) {
  if (startDate == null || endDate == null) return null;
  final todayDate = DateTime(today.year, today.month, today.day);
  if (todayDate.isBefore(startDate) || todayDate.isAfter(endDate)) {
    return startDate;
  }
  return todayDate;
}
