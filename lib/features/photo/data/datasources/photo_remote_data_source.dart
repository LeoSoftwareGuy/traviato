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
}
