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
    required this.questCount,
    required this.stars,
    required this.expenseTotal,
    this.wrapUpPublishedAt,
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
      questCount: 0,
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
      questCount: questCount,
      stars: stars,
      expenseTotal: expenseTotal,
      wrapUpPublishedAt: wrapUpPublishedAt,
    );
  }

  /// Applied when [WrapUpPublishedDispatched] arrives (docs/08's event bus) —
  /// the wrap-up page's own "Keep forever" tap, echoed here so the Home grid
  /// card updates live instead of waiting for the next `trip_card_view` read.
  TripCardEntity copyWithWrapUpPublished(DateTime publishedAt) =>
      TripCardEntity(
        id: id,
        userId: userId,
        name: name,
        destination: destination,
        countryCode: countryCode,
        startDate: startDate,
        endDate: endDate,
        vibes: vibes,
        coverImagePath: coverImagePath,
        createdAt: createdAt,
        updatedAt: updatedAt,
        status: status,
        durationDays: durationDays,
        photoCount: photoCount,
        questCount: questCount,
        stars: stars,
        expenseTotal: expenseTotal,
        wrapUpPublishedAt: publishedAt,
      );

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
  final int questCount;
  final int stars;
  final double expenseTotal;
  final DateTime? wrapUpPublishedAt;

  /// The trip's wrap-up has been "Kept forever" (M4-3).
  bool get isKeptForever => wrapUpPublishedAt != null;

  /// The whole trip was already over on the (local) day the memory was
  /// created, so there was never a window to plan it (#164) — quest
  /// planning isn't offered. A trip created mid-way (day 3 of 5) or on its
  /// last day still counts as plannable. Undated trips are never
  /// past-created. The server mirrors this with one day of grace (TRV04),
  /// since it only knows `created_at` in UTC.
  bool get isPastCreated {
    final end = endDate;
    if (end == null) return false;
    final created = createdAt.toLocal();
    final createdDate = DateTime(created.year, created.month, created.day);
    return DateTime(end.year, end.month, end.day).isBefore(createdDate);
  }

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
    questCount,
    stars,
    expenseTotal,
    wrapUpPublishedAt,
  ];
}
