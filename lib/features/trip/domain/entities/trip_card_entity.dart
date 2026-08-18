import 'package:equatable/equatable.dart';

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
