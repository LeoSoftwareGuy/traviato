import 'entities/photo_entity.dart';

/// Orders photos as they happened (#291): oldest first by when each was
/// taken — or, without EXIF, when it was added. Ties fall back to the id so
/// the order is stable across reloads.
int comparePhotosByTime(PhotoEntity a, PhotoEntity b) {
  final byTime = (a.takenAt ?? a.createdAt).compareTo(
    b.takenAt ?? b.createdAt,
  );
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}
