import 'dart:typed_data';

import '../../domain/entities/film_pick.dart';
import '../models/photo_model.dart';

abstract interface class PhotoRemoteDataSource {
  Future<List<PhotoModel>> getPhotosForTrip(String tripId);

  Future<PhotoModel> addPhoto({
    required String id,
    required String tripId,
    DateTime? dayDate,
    required Uint8List bytes,
    required String fileExtension,
    String? caption,
    String? placeText,
    double? lat,
    double? lng,
    DateTime? takenAt,
  });

  /// Deletes the `photos` row via the `delete_photo` RPC, which also takes
  /// back the photo's ✦2 — unless it completed a bonus task, whose stars
  /// all stay (#165).
  Future<void> deletePhotoRow(String id);

  /// Removes the photo's file from the `trip-photos` bucket.
  Future<void> removePhotoFile(String storagePath);

  /// Writes the photo's Wrap-Up Film pick (#294) and returns when it was
  /// stamped — `use_in_wrap_up_set_at` is set server-side by a trigger.
  Future<DateTime?> setFilmPick(String photoId, FilmPick pick);
}
