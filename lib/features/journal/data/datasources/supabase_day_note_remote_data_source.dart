import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/day_note_model.dart';
import 'day_note_remote_data_source.dart';

class SupabaseDayNoteRemoteDataSource implements DayNoteRemoteDataSource {
  SupabaseDayNoteRemoteDataSource({required SupabaseClient client})
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
  Future<DayNoteModel?> getNote({
    required String tripId,
    required DateTime dayDate,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.dayNotes)
          .select()
          .eq('trip_id', tripId)
          .eq('day_date', _dateOnly(dayDate))
          .maybeSingle();
      return row == null ? null : DayNoteModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<DayNoteModel>> getNotesForTrip(String tripId) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.dayNotes)
          .select()
          .eq('trip_id', tripId);
      return rows.map(DayNoteModel.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<DayNoteModel> upsertNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String content,
  }) async {
    _guardAuthenticated();
    try {
      // Update-then-insert rather than a Postgres upsert, so an edit keeps
      // its original row id instead of the payload's id overwriting it on
      // conflict.
      final updated = await _client
          .from(Tables.dayNotes)
          .update({'content': content})
          .eq('trip_id', tripId)
          .eq('day_date', _dateOnly(dayDate))
          .select();
      final DayNoteModel model;
      if (updated.isNotEmpty) {
        model = DayNoteModel.fromJson(updated.first);
      } else {
        final inserted = await _client
            .from(Tables.dayNotes)
            .insert({
              'id': id,
              'trip_id': tripId,
              'day_date': _dateOnly(dayDate),
              'content': content,
            })
            .select()
            .single();
        model = DayNoteModel.fromJson(inserted);
      }

      // Idempotent via the ledger's unique (user_id, source, source_id)
      // constraint — the note keeps its original id across edits, so only
      // the first save actually inserts a row.
      await _awardPointsQuietly(sourceId: model.id, tripId: tripId);

      return model;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Awards ✦1 for the note. Never throws — a ledger hiccup must not fail
  /// an already-saved note (mirrors #64/#30's award).
  Future<void> _awardPointsQuietly({
    required String sourceId,
    required String tripId,
  }) async {
    try {
      await _client.rpc(
        DBFunctions.awardPoints,
        params: {
          'p_source': 'note',
          'p_source_id': sourceId,
          'p_trip_id': tripId,
        },
      );
    } catch (e) {
      debugPrint('award_points(note, $sourceId) failed: $e');
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
