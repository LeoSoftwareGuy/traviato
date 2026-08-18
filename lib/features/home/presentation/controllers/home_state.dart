import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';

class HomeState extends Equatable {
  const HomeState({required this.trips});

  final List<TripCardEntity> trips;

  bool get isEmpty => trips.isEmpty;

  List<TripCardEntity> get _activeByStartDate {
    final active =
        trips
            .where(
              (t) =>
                  t.status == TripStatus.current ||
                  t.status == TripStatus.upcoming,
            )
            .toList()
          ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    return active;
  }

  /// The single soonest current/upcoming trip, featured as the "Up next"
  /// hero card. Null when nothing is running or on the calendar yet.
  TripCardEntity? get heroTrip =>
      _activeByStartDate.isEmpty ? null : _activeByStartDate.first;

  /// Current/upcoming trips after the hero, for the "Coming up" row.
  List<TripCardEntity> get upcomingTrips {
    final active = _activeByStartDate;
    return active.length <= 1 ? const [] : active.sublist(1);
  }

  /// Finished trips, most recently ended first, for the "Memories" grid.
  List<TripCardEntity> get finishedTrips {
    final finished =
        trips.where((t) => t.status == TripStatus.finished).toList()..sort(
          (a, b) => (b.endDate ?? b.createdAt).compareTo(
            a.endDate ?? a.createdAt,
          ),
        );
    return finished;
  }

  HomeState copyWith({List<TripCardEntity>? trips}) =>
      HomeState(trips: trips ?? this.trips);

  @override
  List<Object?> get props => [trips];
}
