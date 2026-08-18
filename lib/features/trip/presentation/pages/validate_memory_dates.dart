/// Mirrors the `trips_end_date_after_start_date` DB check client-side so the
/// form can show an inline error before submitting.
String? validateMemoryDates(DateTime? start, DateTime? end) {
  if (start != null && end != null && end.isBefore(start)) {
    return "End date can't be before the start date.";
  }
  return null;
}
