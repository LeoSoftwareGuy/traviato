import '../models/wrap_up_model.dart';

abstract interface class WrapUpRemoteDataSource {
  Future<WrapUpModel> getOrGenerate(String tripId);

  Future<void> publish(String tripId);
}
