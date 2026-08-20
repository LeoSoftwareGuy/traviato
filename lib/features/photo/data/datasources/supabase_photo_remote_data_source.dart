import 'dart:io';

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

      // The trip-photos bucket is private: thumbnails need a signed URL
      // rather than a public one.
      final signedResults = await _client.storage
          .from(Storage.tripPhotos)
          .createSignedUrlsResult(
            [for (final p in photos) p.storagePath],
            _signedUrlTtlSeconds,
          );
      final urlByPath = {
        for (final result in signedResults)
          if (result is SignedUrlSuccess) result.path: result.signedUrl,
      };
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
