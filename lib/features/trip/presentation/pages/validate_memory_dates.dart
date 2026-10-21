import '../../../../core/l10n/context_l10n.dart';

/// Mirrors the `trips` date rules client-side so the form can show an
/// inline error before submitting: both dates are required (#270, `not
/// null` columns) and end can't precede start
/// (`trips_end_date_after_start_date`).
///
/// [requireBoth] is false while the user is still filling the form in, so
/// picking a start date doesn't flag the not-yet-picked end date.
String? validateMemoryDates(
  AppLocalizations l10n,
  DateTime? start,
  DateTime? end, {
  bool requireBoth = true,
}) {
  if (requireBoth && (start == null || end == null)) {
    return l10n.trip_datesRequired;
  }
  if (start != null && end != null && end.isBefore(start)) {
    return l10n.trip_endBeforeStart;
  }
  return null;
}
