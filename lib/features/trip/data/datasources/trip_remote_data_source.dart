import 'dart:typed_data';

import '../models/trip_card_model.dart';
import '../models/trip_dates_change_model.dart';
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

  /// The `set_trip_dates` RPC (#271). With [dryRun] it only counts what
  /// the change would delete; otherwise it applies it and returns the
  /// updated trip plus the deleted photos' storage paths.
  Future<TripDatesChangeModel> setTripDates({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    bool dryRun = false,
  });

  /// Removes the given `trip-photos` objects — the files of photos a date
  /// change deleted (#271).
  Future<void> removePhotoFiles(List<String> storagePaths);

  Future<String> uploadCoverImage({
    required String tripId,
    required Uint8List bytes,
  });

  Future<void> deleteCoverImage(String tripId);

  Future<String> getCoverImageUrl(String storagePath);
}
