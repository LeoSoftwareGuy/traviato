import 'dart:typed_data';

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

  /// Deletes the `photos` row. Stars already awarded for it stay — the
  /// ledger's `source_id` has no FK to `photos` (#165).
  Future<void> deletePhotoRow(String id);

  /// Removes the photo's file from the `trip-photos` bucket.
  Future<void> removePhotoFile(String storagePath);
}
