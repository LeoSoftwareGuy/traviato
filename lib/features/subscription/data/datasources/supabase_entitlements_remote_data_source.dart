import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/entitlement_model.dart';
import 'entitlements_remote_data_source.dart';

class SupabaseEntitlementsRemoteDataSource
    implements EntitlementsRemoteDataSource {
  SupabaseEntitlementsRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<EntitlementModel> getEntitlement() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final row = await _client
          .from(Tables.entitlements)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      // A missing row means the M6-1 signup trigger hasn't run yet (or ran
      // before this account existed) — default to free rather than error,
      // same posture as any other "nothing there yet" read.
      if (row == null) return EntitlementModel.free();
      return EntitlementModel.fromJson(row);
    } on AuthenticationException {
      rethrow;
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

  @override
  Future<EntitlementModel> syncEntitlement() async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final response = await _client.functions.invoke(
        EdgeFunctions.syncEntitlement,
      );
      final data = response.data;
      if (data is! Map) {
        throw const ServerException(
          message: 'Entitlement sync returned an unexpected response.',
        );
      }
      return EntitlementModel.fromJson(Map<String, dynamic>.from(data));
    } on ServerException {
      rethrow;
    } on FunctionException catch (e) {
      throw switch (e.status) {
        401 => AuthenticationException(
          message: e.reasonPhrase ?? 'Invalid session',
        ),
        0 => const NetworkException(),
        _ => ServerException(
          message: e.reasonPhrase ?? 'Entitlement sync failed.',
        ),
      };
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}
