import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/photo_order.dart';

import '../fakes/fake_photo_repository.dart';

void main() {
  group('comparePhotosByTime (#291)', () {
    test('orders by capture time, oldest first', () {
      final photos = [
        buildPhotoEntity(id: 'evening', takenAt: DateTime(2026, 6, 1, 18)),
        buildPhotoEntity(id: 'morning', takenAt: DateTime(2026, 6, 1, 9)),
        buildPhotoEntity(id: 'noon', takenAt: DateTime(2026, 6, 1, 12)),
      ]..sort(comparePhotosByTime);

      expect(photos.map((p) => p.id), ['morning', 'noon', 'evening']);
    });

    test('a photo without capture time is placed by its upload time', () {
      final photos = [
        buildPhotoEntity(
          id: 'uploaded-late',
          createdAt: DateTime(2026, 6, 1, 20),
        ),
        buildPhotoEntity(id: 'taken-noon', takenAt: DateTime(2026, 6, 1, 12)),
        buildPhotoEntity(
          id: 'uploaded-early',
          createdAt: DateTime(2026, 6, 1, 8),
        ),
      ]..sort(comparePhotosByTime);

      expect(photos.map((p) => p.id), [
        'uploaded-early',
        'taken-noon',
        'uploaded-late',
      ]);
    });

    test('capture time wins over upload time', () {
      // Added from the gallery later, but taken first.
      final photos = [
        buildPhotoEntity(
          id: 'second',
          takenAt: DateTime(2026, 6, 1, 12),
          createdAt: DateTime(2026, 6, 1, 12),
        ),
        buildPhotoEntity(
          id: 'first',
          takenAt: DateTime(2026, 6, 1, 9),
          createdAt: DateTime(2026, 6, 1, 22),
        ),
      ]..sort(comparePhotosByTime);

      expect(photos.map((p) => p.id), ['first', 'second']);
    });

    test('equal times fall back to the id, so the order is stable', () {
      final at = DateTime(2026, 6, 1, 9);
      final photos = [
        buildPhotoEntity(id: 'b', takenAt: at),
        buildPhotoEntity(id: 'a', takenAt: at),
      ]..sort(comparePhotosByTime);

      expect(photos.map((p) => p.id), ['a', 'b']);
    });
  });
}
