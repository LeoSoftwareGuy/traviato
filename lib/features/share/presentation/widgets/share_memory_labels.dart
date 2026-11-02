import '../../../../core/l10n/l10n_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';

/// The QR and story card's metadata lines (#311), uppercased by the caller
/// where the design shows an eyebrow.
extension ShareMemoryLabels on TripCardEntity {
  /// `Highlands · 12–16 AUG 2026` (QR meta).
  String placeAndDates(String locale) => [
    if (destination?.trim().isNotEmpty ?? false) destination!.trim(),
    ?dates(locale),
  ].join(' · ');

  /// `Highlands · 5 days` (story card eyebrow).
  String placeAndDays(AppLocalizations l10n) {
    final start = startDate;
    final end = endDate;
    return [
      if (destination?.trim().isNotEmpty ?? false) destination!.trim(),
      if (start != null && end != null)
        l10n.common_dayCount(
          DateTime.utc(end.year, end.month, end.day)
                  .difference(DateTime.utc(start.year, start.month, start.day))
                  .inDays +
              1,
        ),
    ].join(' · ');
  }

  /// `12–16 AUG 2026`, or null for an undated memory.
  String? dates(String locale) {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return null;
    return L10nDates.dateRange(start, end, locale);
  }
}
