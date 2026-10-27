import 'package:equatable/equatable.dart';

import 'film_pick.dart';

/// A photo attached to a memory, optionally tagged to a day/place/people.
/// [imageUrl] is a signed URL resolved at fetch time (the `trip-photos`
/// bucket is private) — it is not a persisted column.
class PhotoEntity extends Equatable {
  const PhotoEntity({
    required this.id,
    required this.tripId,
    this.dayDate,
    required this.storagePath,
    this.caption,
    this.lat,
    this.lng,
    this.placeText,
    this.peopleTags = const [],
    this.takenAt,
    required this.createdAt,
    this.imageUrl,
    this.filmPick = FilmPick.auto,
    this.filmPickSetAt,
  });

  final String id;
  final String tripId;
  final DateTime? dayDate;
  final String storagePath;
  final String? caption;
  final double? lat;
  final double? lng;
  final String? placeText;
  final List<String> peopleTags;
  final DateTime? takenAt;
  final DateTime createdAt;
  final String? imageUrl;

  /// The user's Wrap-Up Film pick (#294).
  final FilmPick filmPick;

  /// When [filmPick] last changed (server time) — newer than a kept film's
  /// `generated_at` means the film is out of date.
  final DateTime? filmPickSetAt;

  PhotoEntity copyWith({FilmPick? filmPick, DateTime? filmPickSetAt}) =>
      PhotoEntity(
        id: id,
        tripId: tripId,
        dayDate: dayDate,
        storagePath: storagePath,
        caption: caption,
        lat: lat,
        lng: lng,
        placeText: placeText,
        peopleTags: peopleTags,
        takenAt: takenAt,
        createdAt: createdAt,
        imageUrl: imageUrl,
        filmPick: filmPick ?? this.filmPick,
        filmPickSetAt: filmPickSetAt ?? this.filmPickSetAt,
      );

  @override
  List<Object?> get props => [
    id,
    tripId,
    dayDate,
    storagePath,
    caption,
    lat,
    lng,
    placeText,
    peopleTags,
    takenAt,
    createdAt,
    imageUrl,
    filmPick,
    filmPickSetAt,
  ];
}
