import 'package:equatable/equatable.dart';

import 'trip_entity.dart';

enum TripStatus { undated, upcoming, current, finished }

class TripCardEntity extends Equatable {
  const TripCardEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.destination,
    this.countryCode,
    this.startDate,
    this.endDate,
    this.vibes = const [],
    this.coverImagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.durationDays,
    required this.photoCount,
    required this.stars,
    required this.expenseTotal,
  });

  /// Synthesizes a card for a trip that was just created — no photos, stars
  /// or expenses can exist yet, and status/duration are derived the same
  /// way `trip_card_view` derives them server-side. Lets the create-memory
  /// mutation publish a [TripCreatedDispatched] event without a round trip
  /// through the view.
  factory TripCardEntity.fromNewTrip(TripEntity trip) {
    final (status, durationDays) = _deriveStatusAndDuration(
      trip.startDate,
      trip.endDate,
    );
    return TripCardEntity(
      id: trip.id,
      userId: trip.userId,
      name: trip.name,
      destination: trip.destination,
      countryCode: trip.countryCode,
      startDate: trip.startDate,
      endDate: trip.endDate,
      vibes: trip.vibes,
      coverImagePath: trip.coverImagePath,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
      status: status,
      durationDays: durationDays,
      photoCount: 0,
      stars: 0,
      expenseTotal: 0,
    );
  }

  /// Rebuilds this card after a rename, cover change, or date shift — an
  /// `updateTrip`/`shiftTripDates` call only ever returns the raw `trips`
  /// row, not a fresh `trip_card_view` read. `status`/`durationDays` are
  /// recomputed from the new dates; `photoCount`/`stars`/`expenseTotal`
  /// (derived from other tables `trips` doesn't touch) carry over unchanged.
  TripCardEntity mergeUpdatedTrip(TripEntity trip) {
    final (status, durationDays) = _deriveStatusAndDuration(
      trip.startDate,
      trip.endDate,
    );
    return TripCardEntity(
      id: trip.id,
      userId: trip.userId,
      name: trip.name,
      destination: trip.destination,
      countryCode: trip.countryCode,
      startDate: trip.startDate,
      endDate: trip.endDate,
      vibes: trip.vibes,
      coverImagePath: trip.coverImagePath,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
      status: status,
      durationDays: durationDays,
      photoCount: photoCount,
      stars: stars,
      expenseTotal: expenseTotal,
    );
  }

  static (TripStatus, int?) _deriveStatusAndDuration(
    DateTime? start,
    DateTime? end,
  ) {
    if (start == null || end == null) return (TripStatus.undated, null);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final TripStatus status;
    if (todayDate.isBefore(start)) {
      status = TripStatus.upcoming;
    } else if (todayDate.isAfter(end)) {
      status = TripStatus.finished;
    } else {
      status = TripStatus.current;
    }
    return (status, end.difference(start).inDays + 1);
  }

  final String id;
  final String userId;
  final String name;
  final String? destination;
  final String? countryCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> vibes;
  final String? coverImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripStatus status;
  final int? durationDays;
  final int photoCount;
  final int stars;
  final double expenseTotal;

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    destination,
    countryCode,
    startDate,
    endDate,
    vibes,
    coverImagePath,
    createdAt,
    updatedAt,
    status,
    durationDays,
    photoCount,
    stars,
    expenseTotal,
  ];
}
