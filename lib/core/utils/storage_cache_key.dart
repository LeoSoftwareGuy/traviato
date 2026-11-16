/// The on-device image cache key for a Supabase Storage link: the object's
/// path inside its bucket (`{user_id}/{trip_id}/{photo_id}.jpg`), or null
/// when [url] isn't a Storage object link (then callers cache by URL).
///
/// Private photos load through signed links whose `token` changes with
/// every signing (they expire after an hour), so caching by the full link
/// downloads the same photo again each time (#376). The path is stable, and
/// it's the key `StoragePhotoImage` already uses, so a photo seen in the
/// Journal is a cache hit in the film too.
String? storageCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  final object = segments.indexOf('object');
  // .../storage/v1/object/{sign|public|authenticated}/{bucket}/{path...}
  // and the transform form .../storage/v1/render/image/{sign|public}/...
  final int pathStart;
  if (object > 0 && segments[object - 1] == 'v1') {
    pathStart = object + 3;
  } else {
    final render = segments.indexOf('render');
    if (render <= 0 ||
        segments[render - 1] != 'v1' ||
        render + 1 >= segments.length ||
        segments[render + 1] != 'image') {
      return null;
    }
    pathStart = render + 4;
  }
  if (pathStart >= segments.length) return null;
  final path = segments.sublist(pathStart).join('/');
  return path.isEmpty ? null : path;
}
