import '../../../../core/l10n/context_l10n.dart';

/// Mirrors the `trips_end_date_after_start_date` DB check client-side so the
/// form can show an inline error before submitting.
String? validateMemoryDates(
  AppLocalizations l10n,
  DateTime? start,
  DateTime? end,
) {
  if (start != null && end != null && end.isBefore(start)) {
    return l10n.trip_endBeforeStart;
  }
  return null;
}
