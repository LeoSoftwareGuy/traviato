import 'package:equatable/equatable.dart';

/// The film's cover image reference — same `asset:<id>` / storage-path
/// convention as `trips.cover_image_path` (docs/data-model.md), resolved the
/// same way `TripCoverImage` resolves it elsewhere in the app.
class WrapUpCoverPhoto extends Equatable {
  const WrapUpCoverPhoto({this.imagePath});

  final String? imagePath;

  @override
  List<Object?> get props => [imagePath];
}
