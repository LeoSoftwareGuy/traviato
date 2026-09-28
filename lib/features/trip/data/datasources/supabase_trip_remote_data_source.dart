import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trip_card_model.dart';
import '../models/trip_model.dart';
import 'trip_remote_data_source.dart';

/// Signed URLs are valid for an hour — long enough for a single screen's
/// worth of trip-card renders; callers re-sign on the next load.
const _signedUrlTtlSeconds = 3600;

/// Stable per-trip path — a re-upload replaces the same object rather than
/// accumulating (see [SupabaseTripRemoteDataSource.uploadCoverImage]).
String _coverStoragePath({required String userId, required String tripId}) =>
    '$userId/$tripId/cover.jpg';

/// Files listed (and removed) per round in [SupabaseTripRemoteDataSource
/// .removeTripFiles].
const _removeBatchSize = 1000;

/// Upper bound on list-and-remove rounds — comfortably above the 2,000
/// photos/memory ceiling (TRV03) plus a cover, so a listing that somehow
/// never empties can't spin forever.
const _maxRemoveRounds = 5;

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
      if (e.code == PostgresErrors.freeTierMemoryLimit) {
        throw MemoryLimitException(message: e.message);
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
  Future<String> uploadCoverImage({
    required String tripId,
    required Uint8List bytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    final path = _coverStoragePath(userId: user.id, tripId: tripId);
    try {
      // Best-effort: nothing there yet on a first upload, or a transient
      // hiccup — the upload below is what actually matters. This bucket
      // has no update policy (see the trip-photos migration), so a
      // replace is delete-then-insert rather than an upsert.
      await _client.storage.from(Storage.tripPhotos).remove([path]);
    } catch (_) {
      // Ignored — see above.
    }
    try {
      await _client.storage.from(Storage.tripPhotos).uploadBinary(path, bytes);
      return path;
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCoverImage(String tripId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    final path = _coverStoragePath(userId: user.id, tripId: tripId);
    try {
      await _client.storage.from(Storage.tripPhotos).remove([path]);
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<String> getCoverImageUrl(String storagePath) async {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    try {
      return await _client.storage
          .from(Storage.tripPhotos)
          .createSignedUrl(storagePath, _signedUrlTtlSeconds);
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<void> removeTripFiles(String tripId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
    final folder = '${user.id}/$tripId';
    final bucket = _client.storage.from(Storage.tripPhotos);
    try {
      // Always re-list from the start: each round removes what it saw, so
      // the next listing only holds whatever is left.
      for (var round = 0; round < _maxRemoveRounds; round++) {
        final files = await bucket.list(
          path: folder,
          searchOptions: const SearchOptions(limit: _removeBatchSize),
        );
        if (files.isEmpty) return;
        await bucket.remove([for (final f in files) '$folder/${f.name}']);
        if (files.length < _removeBatchSize) return;
      }
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
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
