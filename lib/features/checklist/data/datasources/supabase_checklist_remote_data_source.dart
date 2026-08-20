import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/checklist_category.dart';
import '../models/checklist_item_model.dart';
import '../models/checklist_suggestion_model.dart';
import 'checklist_remote_data_source.dart';

class SupabaseChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  SupabaseChecklistRemoteDataSource({required SupabaseClient client})
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
  Future<List<ChecklistItemModel>> getItems(String tripId) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.checklistItems)
          .select()
          .eq('trip_id', tripId)
          .order('category')
          .order('position');
      return rows
          .map((row) => ChecklistItemModel.fromJson(row))
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
  Future<List<ChecklistSuggestionModel>> getSuggestions() async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.checklistSuggestions)
          .select()
          .order('category')
          .order('id');
      return rows
          .map((row) => ChecklistSuggestionModel.fromJson(row))
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
  Future<ChecklistItemModel> addItem({
    required String id,
    required String tripId,
    required ChecklistCategory category,
    required String title,
    required int position,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.checklistItems)
          .insert({
            'id': id,
            'trip_id': tripId,
            'title': title,
            'category': category.dbValue,
            'is_essential': false,
            'position': position,
          })
          .select()
          .single();
      return ChecklistItemModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<ChecklistItemModel> toggleChecked({
    required String id,
    required bool checked,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.checklistItems)
          .update({'is_checked': checked})
          .eq('id', id)
          .select()
          .single();
      return ChecklistItemModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    _guardAuthenticated();
    try {
      await _client.from(Tables.checklistItems).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<ChecklistItemModel>> insertItems(
    List<ChecklistItemDraft> items,
  ) async {
    _guardAuthenticated();
    try {
      final rows = await _client.from(Tables.checklistItems).insert([
        for (final item in items)
          {
            'id': item.id,
            'trip_id': item.tripId,
            'title': item.title,
            'category': item.category.dbValue,
            'is_essential': item.isEssential,
            'position': item.position,
          },
      ]).select();
      return rows
          .map((row) => ChecklistItemModel.fromJson(row))
          .toList(growable: false);
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
