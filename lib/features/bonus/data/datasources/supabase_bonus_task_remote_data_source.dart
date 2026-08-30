import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/bonus_task_assignment_model.dart';
import '../models/bonus_task_template_model.dart';
import 'bonus_task_remote_data_source.dart';

class SupabaseBonusTaskRemoteDataSource implements BonusTaskRemoteDataSource {
  SupabaseBonusTaskRemoteDataSource({required SupabaseClient client})
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
  Future<List<BonusTaskTemplateModel>> getTemplates() async {
    _guardAuthenticated();
    try {
      final rows = await _client.from(Tables.bonusTaskTemplates).select();
      return rows
          .map((row) => BonusTaskTemplateModel.fromJson(row))
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
  Future<List<BonusTaskAssignmentModel>> getAssignmentsForTrip(
    String tripId,
  ) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.bonusTaskAssignments)
          .select()
          .eq('trip_id', tripId)
          .order('day_date');
      return rows
          .map((row) => BonusTaskAssignmentModel.fromJson(row))
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
  Future<List<BonusTaskAssignmentModel>> assignForDay({
    required String tripId,
    required DateTime dayDate,
    required List<(String id, int templateId)> assignments,
  }) async {
    _guardAuthenticated();
    final dayDateString = _dateOnly(dayDate);
    try {
      if (assignments.isNotEmpty) {
        // ON CONFLICT DO NOTHING — the unique (trip_id, template_id,
        // day_date) constraint absorbs a race between two opens on the
        // same day, so this insert never fails even if some rows already
        // exist.
        await _client
            .from(Tables.bonusTaskAssignments)
            .upsert(
              [
                for (final (id, templateId) in assignments)
                  {
                    'id': id,
                    'trip_id': tripId,
                    'template_id': templateId,
                    'day_date': dayDateString,
                  },
              ],
              onConflict: 'trip_id,template_id,day_date',
              ignoreDuplicates: true,
            );
      }
      final rows = await _client
          .from(Tables.bonusTaskAssignments)
          .select()
          .eq('trip_id', tripId)
          .eq('day_date', dayDateString);
      return rows
          .map((row) => BonusTaskAssignmentModel.fromJson(row))
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
  Future<BonusTaskAssignmentModel> completeAssignment({
    required String id,
    required String tripId,
    required String photoId,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.bonusTaskAssignments)
          .update({
            'completed_at': DateTime.now().toIso8601String(),
            'photo_id': photoId,
          })
          .eq('id', id)
          .select()
          .single();
      final model = BonusTaskAssignmentModel.fromJson(row);

      await _awardPointsQuietly(sourceId: id, tripId: tripId);
      await _checkAchievementsQuietly();

      return model;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Awards the task's own points. Never throws — a ledger hiccup must not
  /// fail an already-completed task (mirrors #30's photo award).
  Future<void> _awardPointsQuietly({
    required String sourceId,
    required String tripId,
  }) async {
    try {
      await _client.rpc(
        DBFunctions.awardPoints,
        params: {
          'p_source': 'bonus_task',
          'p_source_id': sourceId,
          'p_trip_id': tripId,
        },
      );
    } catch (e) {
      debugPrint('award_points(bonus_task, $sourceId) failed: $e');
    }
  }

  /// Best-effort achievement re-check. Never throws — same reasoning as
  /// [_awardPointsQuietly].
  Future<void> _checkAchievementsQuietly() async {
    try {
      await _client.rpc(DBFunctions.checkAchievements);
    } catch (e) {
      debugPrint('check_achievements() failed: $e');
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
