import 'dart:typed_data';

import '../models/share_link_model.dart';

abstract interface class ShareRemoteDataSource {
  /// `create_share_link`: the memory's active link, made if there is none.
  Future<ShareLinkModel> createLink(String tripId);

  /// The memory's active link, or null.
  Future<ShareLinkModel?> getActiveLink(String tripId);

  /// `revoke_share_link`: a no-op when there is no active link.
  Future<void> revokeLink(String tripId);

  /// An original from the private `trip-photos` bucket.
  Future<Uint8List> downloadPhoto(String storagePath);

  /// Writes (or overwrites) a file in the public `share-previews` bucket.
  Future<void> uploadPreviewFile(String path, Uint8List bytes);

  /// Removes files from `share-previews`; missing ones are ignored.
  Future<void> removePreviewFiles(List<String> paths);

  /// `mark_share_preview_built`.
  Future<void> markPreviewBuilt(String linkId, int photoCount);
}
