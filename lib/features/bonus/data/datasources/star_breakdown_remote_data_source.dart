import '../models/star_ledger_group_model.dart';

abstract interface class StarBreakdownRemoteDataSource {
  Future<List<StarLedgerGroupModel>> getBreakdown();
}
