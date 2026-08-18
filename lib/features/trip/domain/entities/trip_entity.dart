import 'package:equatable/equatable.dart';

/// A raw `trips` row — what an insert/update can honestly return. Distinct
/// from [TripCardEntity], which layers on `trip_card_view`'s derived
/// columns (status, stars, photo count, ...) for display.
class TripEntity extends Equatable {
  const TripEntity({
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
  });

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
  ];
}
