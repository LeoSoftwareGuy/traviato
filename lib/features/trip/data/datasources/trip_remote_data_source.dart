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
}
