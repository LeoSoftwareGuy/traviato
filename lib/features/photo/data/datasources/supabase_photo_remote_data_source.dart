import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/photo_model.dart';
import 'photo_remote_data_source.dart';

/// Signed URLs are valid for an hour — long enough for a single Journal
/// screen session; the strip re-fetches (and re-signs) on the next open.
const _signedUrlTtlSeconds = 3600;

class SupabasePhotoRemoteDataSource implements PhotoRemoteDataSource {
  SupabasePhotoRemoteDataSource({required SupabaseClient client})
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
  Future<List<PhotoModel>> getPhotosForTrip(String tripId) async {
    _guardAuthenticated();
    try {
      final rows = await _client
          .from(Tables.photos)
          .select()
          .eq('trip_id', tripId)
          .order('day_date', nullsFirst: false)
          .order('created_at');
      final photos = rows
          .map((row) => PhotoModel.fromJson(row))
          .toList(growable: false);
      if (photos.isEmpty) return photos;

      final urlByPath = await _signPaths([
        for (final p in photos) p.storagePath,
      ]);
      return [
        for (final photo in photos)
          photo.withImageUrl(urlByPath[photo.storagePath]),
      ];
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<PhotoModel> addPhoto({
    required String id,
    required String tripId,
    DateTime? dayDate,
    required Uint8List bytes,
    required String fileExtension,
    String? caption,
    String? placeText,
    double? lat,
    double? lng,
    DateTime? takenAt,
  }) async {
    _guardAuthenticated();
    final userId = _client.auth.currentUser!.id;
    final storagePath = '$userId/$tripId/$id.$fileExtension';
    try {
      await _client.storage
          .from(Storage.tripPhotos)
          .uploadBinary(storagePath, bytes);

      final row = await _client
          .from(Tables.photos)
          .insert({
            'id': id,
            'trip_id': tripId,
            'day_date': dayDate == null ? null : _dateOnly(dayDate),
            'storage_path': storagePath,
            'caption': caption,
            'place_text': placeText,
            'lat': lat,
            'lng': lng,
            'taken_at': takenAt?.toIso8601String(),
          })
          .select()
          .single();
      final photo = PhotoModel.fromJson(row);

      final urlByPath = await _signPaths([storagePath]);
      final withUrl = photo.withImageUrl(urlByPath[storagePath]);

      await _awardPointsQuietly(sourceId: id, tripId: tripId);
      return withUrl;
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  /// Awards ✦2 for the new photo. Never throws — a ledger hiccup must not
  /// fail an already-uploaded photo (issue #30 AC).
  Future<void> _awardPointsQuietly({
    required String sourceId,
    required String tripId,
  }) async {
    try {
      await _client.rpc(
        DBFunctions.awardPoints,
        params: {
          'p_source': 'photo',
          'p_source_id': sourceId,
          'p_trip_id': tripId,
        },
      );
    } catch (e) {
      debugPrint('award_points(photo, $sourceId) failed: $e');
    }
  }

  /// The `trip-photos` bucket is private: thumbnails need signed URLs
  /// rather than public ones.
  Future<Map<String, String>> _signPaths(List<String> paths) async {
    final results = await _client.storage
        .from(Storage.tripPhotos)
        .createSignedUrlsResult(paths, _signedUrlTtlSeconds);
    return {
      for (final result in results)
        if (result is SignedUrlSuccess) result.path: result.signedUrl,
    };
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
