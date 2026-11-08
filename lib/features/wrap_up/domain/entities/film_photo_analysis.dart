import 'package:equatable/equatable.dart';

/// What the director's vision call saw in one photo (#328,
/// `photo_analysis`) — shown under each thumbnail in the Plan inspector.
class FilmPhotoAnalysis extends Equatable {
  const FilmPhotoAnalysis({
    required this.photoId,
    required this.summary,
    required this.setting,
    required this.people,
    required this.energy,
    required this.quality,
    required this.heroScore,
    this.dupGroup,
  });

  final String photoId;
  final String summary;
  final String setting;
  final String people;
  final String energy;
  final String quality;
  final int heroScore;
  final String? dupGroup;

  @override
  List<Object?> get props => [
    photoId,
    summary,
    setting,
    people,
    energy,
    quality,
    heroScore,
    dupGroup,
  ];
}
