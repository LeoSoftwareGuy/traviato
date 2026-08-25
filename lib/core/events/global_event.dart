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
