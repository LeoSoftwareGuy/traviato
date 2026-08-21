import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/expense_category.dart';
import '../models/expense_model.dart';
import 'expense_remote_data_source.dart';

class SupabaseExpenseRemoteDataSource implements ExpenseRemoteDataSource {
  SupabaseExpenseRemoteDataSource({required SupabaseClient client})
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
  Future<Map<String, int>> getExpenseItemCounts() async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Views.expenseSummaryView)
          .select('trip_id, item_count');
      return {
        for (final row in rows)
          row['trip_id'] as String: (row['item_count'] as num).toInt(),
      };
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesForTrip(String tripId) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.expenses)
          .select()
          .eq('trip_id', tripId)
          .order('spent_on', ascending: false);
      return rows
          .map((row) => ExpenseModel.fromJson(row))
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
  Future<ExpenseModel> addExpense({
    required String id,
    required String tripId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required DateTime spentOn,
  }) async {
    _guardAuthenticated();
    try {
      final row = await _client
          .from(Tables.expenses)
          .insert({
            'id': id,
            'trip_id': tripId,
            'title': title,
            'amount': amount,
            'category': category.dbValue,
            'spent_on': spentOn.toIso8601String().split('T').first,
          })
          .select()
          .single();
      return ExpenseModel.fromJson(row);
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
