import 'dart:typed_data';

import '../models/trip_card_model.dart';
import '../models/trip_model.dart';

abstract interface class TripRemoteDataSource {
  Future<List<TripCardModel>> getTripCards();

  Future<TripCardModel> getTripCard(String tripId);

  Future<TripModel> createTrip({
    required String id,
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes,
    String? coverImagePath,
  });

  Future<void> deleteTrip(String id);

  /// Removes every file under the trip's `trip-photos` folder
  /// (`{user_id}/{trip_id}/` — journal photos and a custom cover). The row
  /// cascade can't do this: Postgres can't delete storage objects (#170).
  Future<void> removeTripFiles(String tripId);

  Future<TripModel> updateTrip({
    required String id,
    String? name,
    String? coverImagePath,
  });

  Future<TripModel> shiftTripDates({
    required String id,
    required int deltaDays,
  });

  Future<String> uploadCoverImage({
    required String tripId,
    required Uint8List bytes,
  });

  Future<void> deleteCoverImage(String tripId);

  Future<String> getCoverImageUrl(String storagePath);
}
