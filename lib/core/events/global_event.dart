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
