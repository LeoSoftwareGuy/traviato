import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/journal_note_model.dart';
import 'journal_note_remote_data_source.dart';

class SupabaseJournalNoteRemoteDataSource
    implements JournalNoteRemoteDataSource {
  SupabaseJournalNoteRemoteDataSource({required SupabaseClient client})
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
  Future<List<JournalNoteModel>> getNotesForDay({
    required String tripId,
    required DateTime dayDate,
  }) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.journalNotes)
          .select()
          .eq('trip_id', tripId)
          .eq('day_date', _dateOnly(dayDate))
          .order('taken_at');
      return rows.map(JournalNoteModel.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<JournalNoteModel>> getNotesForTrip(String tripId) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.journalNotes)
          .select()
          .eq('trip_id', tripId)
          .order('taken_at');
      return rows.map(JournalNoteModel.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<JournalNoteModel> createNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required DateTime takenAt,
    required String content,
    required bool dictated,
    String? photoId,
  }) async {
    _guardAuthenticated();
    try {
      final inserted = await _client
          .from(Tables.journalNotes)
          .insert({
            'id': id,
            'trip_id': tripId,
            'day_date': _dateOnly(dayDate),
            'taken_at': takenAt.toUtc().toIso8601String(),
            'edited_at': takenAt.toUtc().toIso8601String(),
            'content': content,
            'dictated': dictated,
            'photo_id': ?photoId,
          })
          .select()
          .single();
      final model = JournalNoteModel.fromJson(inserted);

      // Idempotent via the ledger's unique (user_id, source, source_id);
      // the server skips it once the day has 3 note-stars.
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

  @override
  Future<JournalNoteModel> updateNote({
    required String id,
    required String content,
    required bool dictated,
  }) async {
    _guardAuthenticated();
    try {
      // taken_at, legacy and edited_at are kept or stamped by a trigger.
      final updated = await _client
          .from(Tables.journalNotes)
          .update({'content': content, 'dictated': dictated})
          .eq('id', id)
          .select()
          .single();
      return JournalNoteModel.fromJson(updated);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    _guardAuthenticated();
    try {
      // A plain RLS delete: the note's star stays (#397).
      await _client.from(Tables.journalNotes).delete().eq('id', id);
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
