import 'package:equatable/equatable.dart';

/// A bare reference to one of the trip's photos — resolved to an actual
/// image via the already-fetched `photoUrlById` map, same pattern the old
/// photo-beat block used. `storage_path` from #125's JSON is redundant with
/// that map and intentionally not carried here.
class WrapUpPhotoRef extends Equatable {
  const WrapUpPhotoRef({required this.photoId, this.dayDate});

  final String photoId;
  final DateTime? dayDate;

  @override
  List<Object?> get props => [photoId, dayDate];
}
