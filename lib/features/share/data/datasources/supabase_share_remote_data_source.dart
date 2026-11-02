import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/share_link_model.dart';
import 'share_remote_data_source.dart';

/// Chat apps cache link-preview images for days anyway; a short CDN cache
/// lets a rebuilt preview show up soon for anyone fetching it fresh.
const _previewCacheSeconds = '300';

class SupabaseShareRemoteDataSource implements ShareRemoteDataSource {
  SupabaseShareRemoteDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  void _guardAuthenticated() {
    if (_client.auth.currentUser == null) {
      throw const AuthenticationException(
        message: 'User is not authenticated',
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    _guardAuthenticated();
    try {
      return await body();
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on StorageException catch (e) {
      throw StorageServerException(message: e.message);
    } on SocketException {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(message: e.toString());
    }
  }

  @override
  Future<ShareLinkModel> createLink(String tripId) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      DBFunctions.createShareLink,
      params: {'p_trip_id': tripId},
    );
    return ShareLinkModel.fromJson(row);
  });

  @override
  Future<ShareLinkModel?> getActiveLink(String tripId) => _guard(() async {
    final row = await _client
        .from(Tables.tripShareLinks)
        .select()
        .eq('trip_id', tripId)
        .isFilter('revoked_at', null)
        .maybeSingle();
    return row == null ? null : ShareLinkModel.fromJson(row);
  });

  @override
  Future<void> revokeLink(String tripId) => _guard(
    () => _client.rpc<void>(
      DBFunctions.revokeShareLink,
      params: {'p_trip_id': tripId},
    ),
  );

  @override
  Future<Uint8List> downloadPhoto(String storagePath) => _guard(
    () => _client.storage.from(Storage.tripPhotos).download(storagePath),
  );

  @override
  Future<void> uploadPreviewFile(String path, Uint8List bytes) => _guard(
    () => _client.storage
        .from(Storage.sharePreviews)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
            cacheControl: _previewCacheSeconds,
          ),
        ),
  );

  @override
  Future<void> removePreviewFiles(List<String> paths) =>
      _guard(() => _client.storage.from(Storage.sharePreviews).remove(paths));

  @override
  Future<void> markPreviewBuilt(String linkId, int photoCount) => _guard(
    () => _client.rpc<void>(
      DBFunctions.markSharePreviewBuilt,
      params: {'p_link_id': linkId, 'p_photo_count': photoCount},
    ),
  );
}

AppException _mapPostgrestException(PostgrestException e) {
  if (e.code == PostgresErrors.insufficientPrivilege) {
    return PermissionException(message: e.message);
  }
  return DatabaseException(message: e.message);
}
