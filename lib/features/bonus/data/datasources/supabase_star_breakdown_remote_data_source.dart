import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/star_ledger_group_model.dart';
import 'star_breakdown_remote_data_source.dart';

class SupabaseStarBreakdownRemoteDataSource
    implements StarBreakdownRemoteDataSource {
  SupabaseStarBreakdownRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<List<StarLedgerGroupModel>> getBreakdown() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final rows = await _client
          .from(Views.starBreakdownView)
          .select()
          .eq('user_id', userId);
      return rows
          .map((row) => StarLedgerGroupModel.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}
