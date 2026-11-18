import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/utils/storage_cache_key.dart';

void main() {
  const base = 'https://abc.supabase.co/storage/v1';

  group('storageCacheKey', () {
    test('a signed link keys on the object path, not the token', () {
      expect(
        storageCacheKey('$base/object/sign/trip-photos/u1/t1/p1.jpg?token=aaa'),
        'u1/t1/p1.jpg',
      );
    });

    test('two signings of one photo share a key', () {
      expect(
        storageCacheKey('$base/object/sign/trip-photos/u/t/p.jpg?token=one'),
        storageCacheKey('$base/object/sign/trip-photos/u/t/p.jpg?token=two'),
      );
    });

    test('public, authenticated and render links key on the path too', () {
      expect(
        storageCacheKey('$base/object/public/avatars/u/avatar.jpg'),
        'u/avatar.jpg',
      );
      expect(
        storageCacheKey('$base/object/authenticated/trip-photos/u/t/p.jpg'),
        'u/t/p.jpg',
      );
      expect(
        storageCacheKey(
          '$base/render/image/sign/trip-photos/u/t/p.jpg?token=x&width=512',
        ),
        'u/t/p.jpg',
      );
    });

    test('matches the storage path the Journal caches under', () {
      const storagePath = 'user-1/trip-1/photo-1.jpg';
      expect(
        storageCacheKey('$base/object/sign/trip-photos/$storagePath?token=t'),
        storagePath,
      );
    });

    test('a non-Storage link has no key, so it caches by URL', () {
      expect(storageCacheKey('https://lh3.googleusercontent.com/a/pic'), null);
      expect(storageCacheKey('https://example.com/moment.jpg'), null);
      expect(storageCacheKey('$base/object/sign/trip-photos'), null);
      expect(storageCacheKey('not a url at all'), null);
    });
  });
}
