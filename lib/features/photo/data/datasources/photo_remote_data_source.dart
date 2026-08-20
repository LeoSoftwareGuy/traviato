import '../models/photo_model.dart';

abstract interface class PhotoRemoteDataSource {
  Future<List<PhotoModel>> getPhotosForTrip(String tripId);
}
