import '../models/wrap_up_model.dart';

abstract interface class WrapUpRemoteDataSource {
  Future<WrapUpModel> getOrGenerate(String tripId, {required String language});

  Future<void> publish(String tripId);

  /// Re-assembles a kept film from the current photos and picks (#294).
  Future<void> rebuildKept(String tripId, {required String language});
}
