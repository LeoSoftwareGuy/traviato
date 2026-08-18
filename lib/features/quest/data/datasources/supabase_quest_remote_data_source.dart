import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/quest_model.dart';
import 'quest_remote_data_source.dart';

class SupabaseQuestRemoteDataSource implements QuestRemoteDataSource {
  SupabaseQuestRemoteDataSource({required SupabaseClient client})
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
  Future<List<QuestModel>> getQuestsForTrip(String tripId) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.quests)
          .select()
          .eq('trip_id', tripId)
          .order('day_date')
          .order('time', nullsFirst: false)
          .order('position');
      return rows
          .map((row) => QuestModel.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<QuestModel> addQuest({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String title,
    Duration? time,
    String? placeText,
    required int position,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.quests)
          .insert({
            'id': id,
            'trip_id': tripId,
            'day_date': _dateOnly(dayDate),
            'title': title,
            'time': formatTimeOfDayString(time),
            'place_text': placeText,
            'position': position,
          })
          .select()
          .single();
      return QuestModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<QuestModel> updateQuest({
    required String id,
    required String title,
    Duration? time,
    String? placeText,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.quests)
          .update({
            'title': title,
            'time': formatTimeOfDayString(time),
            'place_text': placeText,
          })
          .eq('id', id)
          .select()
          .single();
      return QuestModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> deleteQuest(String id) async {
    _guardAuthenticated();
    try {
      await _client.from(Tables.quests).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<QuestModel> toggleCompleted({
    required String id,
    required bool completed,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.quests)
          .update({
            'completed_at': completed ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', id)
          .select()
          .single();
      return QuestModel.fromJson(row);
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

String _dateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
