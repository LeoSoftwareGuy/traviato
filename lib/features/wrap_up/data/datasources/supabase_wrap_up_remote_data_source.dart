import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/wrap_up_model.dart';
import 'wrap_up_remote_data_source.dart';

class SupabaseWrapUpRemoteDataSource implements WrapUpRemoteDataSource {
  SupabaseWrapUpRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  void _guardAuthenticated() {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
  }

  @override
  Future<WrapUpModel> getOrGenerate(String tripId) async {
    _guardAuthenticated();
    try {
      final existing = await _client
          .from(Tables.wrapUps)
          .select('content, generated_at, published_at')
          .eq('trip_id', tripId)
          .maybeSingle();
      if (existing != null && existing['content'] != null) {
        return WrapUpModel.fromRow(existing);
      }

      final response = await _client.functions.invoke(
        EdgeFunctions.generateWrapUp,
        body: {'trip_id': tripId},
      );
      final data = response.data;
      if (data is! Map) {
        throw const ServerException(
          message: 'Wrap-up generation returned an unexpected response.',
        );
      }
      return WrapUpModel.fromRow({
        'content': data['content'],
        'generated_at': data['generated_at'],
        'published_at': null,
      });
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> publish(String tripId) async {
    _guardAuthenticated();
    try {
      await _client
          .from(Tables.wrapUps)
          .update({'published_at': DateTime.now().toUtc().toIso8601String()})
          .eq('trip_id', tripId);
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

AppException _mapFunctionException(FunctionException e) {
  final details = e.details;
  final message = details is Map && details['error'] is String
      ? details['error'] as String
      : e.reasonPhrase ?? 'Wrap-up generation failed.';
  switch (e.status) {
    case 401:
      return AuthenticationException(message: message);
    case 403:
      return PermissionException(message: message);
    case 404:
      return NotFoundException(message: message);
    case 0:
      return const NetworkException();
    default:
      return ServerException(message: message);
  }
}
