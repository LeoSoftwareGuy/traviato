import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trip_card_model.dart';
import '../models/trip_model.dart';
import 'trip_remote_data_source.dart';

class SupabaseTripRemoteDataSource implements TripRemoteDataSource {
  SupabaseTripRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<List<TripCardModel>> getTripCards() async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final rows = await _client
          .from(Views.tripCardView)
          .select()
          .order('start_date', nullsFirst: false);
      return rows
          .map((row) => TripCardModel.fromJson(row))
          .toList(growable: false);
    } on AuthenticationException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<TripCardModel> getTripCard(String tripId) async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final row = await _client
          .from(Views.tripCardView)
          .select()
          .eq('id', tripId)
          .single();
      return TripCardModel.fromJson(row);
    } on AuthenticationException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<TripModel> createTrip({
    required String id,
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes = const [],
    String? coverImagePath,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final row = await _client
          .from(Tables.trips)
          .insert({
            'id': id,
            'user_id': user.id,
            'name': name,
            'destination': destination,
            'start_date': _dateOnly(startDate),
            'end_date': _dateOnly(endDate),
            'vibes': vibes,
            'cover_image_path': coverImagePath,
          })
          .select()
          .single();
      return TripModel.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<TripModel> updateTrip({
    required String id,
    String? name,
    String? coverImagePath,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final row = await _client
          .from(Tables.trips)
          .update({'name': ?name, 'cover_image_path': ?coverImagePath})
          .eq('id', id)
          .select()
          .single();
      return TripModel.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<TripModel> shiftTripDates({
    required String id,
    required int deltaDays,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      final row = await _client.rpc(
        DBFunctions.shiftTripDates,
        params: {'p_trip_id': id, 'p_delta_days': deltaDays},
      );
      return TripModel.fromJson(row as Map<String, dynamic>);
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
  Future<void> deleteTrip(String id) async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      await _client.from(Tables.trips).delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == PostgresErrors.insufficientPrivilege) {
        throw PermissionException(message: e.message);
      }
      if (e.code == PostgresErrors.moreThanOneOrNoItemsReturned) {
        throw NotFoundException(message: e.message);
      }
      throw DatabaseException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }
}

String? _dateOnly(DateTime? date) {
  if (date == null) return null;
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
