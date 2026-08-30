import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/profile_stats_model.dart';
import 'profile_stats_remote_data_source.dart';

class SupabaseProfileStatsRemoteDataSource
    implements ProfileStatsRemoteDataSource {
  SupabaseProfileStatsRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<ProfileStatsModel> getStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final row = await _client
          .from(Views.profileStatsView)
          .select()
          .eq('user_id', userId)
          .single();
      return ProfileStatsModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}

AppException _mapPostgrestException(PostgrestException e) {
  if (e.code == PostgresErrors.insufficientPrivilege) {
    return PermissionException(message: e.message);
  }
  if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
    return NotFoundException(message: e.message);
  }
  return DatabaseException(message: e.message);
}
