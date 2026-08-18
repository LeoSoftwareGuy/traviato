import '../models/trip_card_model.dart';

abstract interface class TripRemoteDataSource {
  Future<List<TripCardModel>> getTripCards();
}
