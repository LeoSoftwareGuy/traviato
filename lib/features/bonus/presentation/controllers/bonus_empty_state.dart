import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/bonus_task_template_entity.dart';
import '../../domain/entities/star_summary.dart';

/// What the Bonus page shows when it's opened without a memory (#219):
/// the tray when one is open today, otherwise one of the designed states.
sealed class BonusEmptyState extends Equatable {
  const BonusEmptyState();

  /// Picks the state for [today] (a local date): a memory under way →
  /// its tray; else the soonest future memory → upcoming; else nothing
  /// upcoming, or brand new when there are no stars yet.
  static BonusEmptyState resolve({
    required List<TripCardEntity> trips,
    required StarSummary summary,
    required DateTime today,
    List<BonusTaskTemplateEntity> Function(TripCardEntity trip)? teasersFor,
  }) {
    final day = _dateOnly(today);
    final active = trips.where((t) => t.isUnderwayOn(day)).toList()
      ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    if (active.isNotEmpty) return BonusTrayActive(tripId: active.first.id);

    final upcoming =
        trips
            .where(
              (t) =>
                  t.startDate != null && _dateOnly(t.startDate!).isAfter(day),
            )
            .toList()
          ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      return BonusUpcoming(
        trip: next,
        daysUntil: daysUntil(next.startDate!, today: day),
        summary: summary,
        teasers: teasersFor?.call(next) ?? const [],
      );
    }

    return summary.hasStars
        ? BonusNothingUpcoming(summary: summary)
        : const BonusBrandNew();
  }

  /// Whole local days from [today] to [date]; 1 = tomorrow. Compares
  /// calendar dates in UTC so a DST change can't shave off an hour and
  /// round a day away.
  static int daysUntil(DateTime date, {required DateTime today}) {
    final to = DateTime.utc(date.year, date.month, date.day);
    final from = DateTime.utc(today.year, today.month, today.day);
    return to.difference(from).inDays;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// A memory is under way today: show its tray (the existing page).
final class BonusTrayActive extends BonusEmptyState {
  const BonusTrayActive({required this.tripId});

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Frame 1a: the next tray opens on [trip]'s first day.
final class BonusUpcoming extends BonusEmptyState {
  const BonusUpcoming({
    required this.trip,
    required this.daysUntil,
    required this.summary,
    required this.teasers,
  });

  final TripCardEntity trip;
  final int daysUntil;
  final StarSummary summary;

  /// Up to two sample tasks from the pool, for "What a tray looks like".
  final List<BonusTaskTemplateEntity> teasers;

  @override
  List<Object?> get props => [trip, daysUntil, summary, teasers];
}

/// Frame 1b: no memory on the way, but stars to show.
final class BonusNothingUpcoming extends BonusEmptyState {
  const BonusNothingUpcoming({required this.summary});

  final StarSummary summary;

  @override
  List<Object?> get props => [summary];
}

/// Frame 1c: no memory on the way and no stars yet.
final class BonusBrandNew extends BonusEmptyState {
  const BonusBrandNew();

  @override
  List<Object?> get props => const [];
}
