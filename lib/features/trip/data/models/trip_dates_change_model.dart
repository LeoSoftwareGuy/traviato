import '../../domain/entities/trip_dates_change_entity.dart';
import 'trip_model.dart';

/// Maps the `set_trip_dates` RPC's jsonb result (#271). [photoPaths] — the
/// deleted photos' storage paths — stays in the data layer: the repository
/// removes those files, callers only see the counts.
class TripDatesChangeModel extends TripDatesChangeEntity {
  const TripDatesChangeModel({
    required super.quests,
    required super.notes,
    required super.photos,
    required super.bonusTasks,
    super.trip,
    this.photoPaths = const [],
  });

  factory TripDatesChangeModel.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'];
    return TripDatesChangeModel(
      quests: (json['quests'] as num).toInt(),
      notes: (json['notes'] as num).toInt(),
      photos: (json['photos'] as num).toInt(),
      bonusTasks: (json['bonus_tasks'] as num).toInt(),
      trip: trip == null
          ? null
          : TripModel.fromJson(Map<String, dynamic>.from(trip as Map)),
      photoPaths: (json['photo_paths'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  final List<String> photoPaths;

  @override
  List<Object?> get props => [...super.props, photoPaths];
}
