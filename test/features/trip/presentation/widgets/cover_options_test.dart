import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/trip/presentation/widgets/cover_options.dart';

void main() {
  group('suggestedCover', () {
    test('returns the option whose vibe matches the selected vibe', () {
      final result = suggestedCover({'Romantic'});
      expect(result.id, 'honeymoon_escape');
    });

    test('returns the first matching option in list order when multiple '
        'vibes are selected', () {
      // 'Road trip' (new_memory, last) and 'Romantic' (honeymoon_escape,
      // 2nd) are both selected — the earlier option in kCoverOptions wins.
      final result = suggestedCover({'Road trip', 'Romantic'});
      expect(result.id, 'honeymoon_escape');
    });

    test('falls back to the first option when no vibe matches', () {
      final result = suggestedCover({'Chill'});
      expect(result.id, kCoverOptions.first.id);
    });

    test('falls back to the first option when no vibes are selected', () {
      final result = suggestedCover(const {});
      expect(result.id, kCoverOptions.first.id);
    });
  });

  group('assetCoverImagePath / resolveAssetCoverPath', () {
    test('round-trips a cover id through the asset: prefix', () {
      final path = assetCoverImagePath('hero');
      expect(path, 'asset:hero');
      expect(resolveAssetCoverPath(path), kCoverOptions.first.assetPath);
    });

    test('returns null for a non-asset path (a real upload URL)', () {
      expect(
        resolveAssetCoverPath('https://example.com/photo.jpg'),
        isNull,
      );
    });

    test('returns null for null', () {
      expect(resolveAssetCoverPath(null), isNull);
    });

    test('returns null for an unrecognized asset id', () {
      expect(resolveAssetCoverPath('asset:not-a-real-id'), isNull);
    });
  });
}
