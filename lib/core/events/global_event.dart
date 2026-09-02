import 'package:equatable/equatable.dart';

import '../../features/trip/domain/entities/trip_card_entity.dart';

/// Cross-feature signals (guidelines doc 08). Each subclass describes a fact
/// that already happened; subscribers only sync their own view.
sealed class GlobalEvent extends Equatable {
  const GlobalEvent();

  @override
  List<Object?> get props => [];
}

final class TripCreatedDispatched extends GlobalEvent {
  const TripCreatedDispatched({required this.trip});

  final TripCardEntity trip;

  @override
  List<Object?> get props => [trip];
}

final class TripDeletedDispatched extends GlobalEvent {
  const TripDeletedDispatched({required this.tripId});

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Fired after a rename, cover change, or date shift — the manage memory
/// sheet's edits (`docs/design/README.md` Shared: Manage memory sheet).
final class TripUpdatedDispatched extends GlobalEvent {
  const TripUpdatedDispatched({required this.trip});

  final TripCardEntity trip;

  @override
  List<Object?> get props => [trip];
}

/// Fired after any action that awards stars — quest check-off, day-note
/// save, photo add, bonus-task completion (issue #77). No payload: the
/// only subscriber is the Home stars/stats badge, which just refetches the
/// aggregate `profile_stats_view` rather than reconciling an amount.
final class StarsAwardedDispatched extends GlobalEvent {
  const StarsAwardedDispatched();
}

/// Fired after "Keep forever" publishes a wrap-up (issue #95), so the Home
/// "Kept forever" grid card reflects the new state without waiting for its
/// next `trip_card_view` fetch.
final class WrapUpPublishedDispatched extends GlobalEvent {
  const WrapUpPublishedDispatched({
    required this.tripId,
    required this.publishedAt,
  });

  final String tripId;
  final DateTime publishedAt;

  @override
  List<Object?> get props => [tripId, publishedAt];
}
